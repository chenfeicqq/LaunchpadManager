//
//  LaunchpadImporter.swift
//  LaunchpadManager
//
//  Created by 陈飞 on 2025/4/12.
//

import Foundation
import SQLite3

class LaunchpadCleaner {
    
    static func cleanLayout() throws {

        let dbPath = try LaunchpadDB.getDBPath()
        
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        defer { sqlite3_close(db) }
        
        
        let groups = try fetchGroups(db: db)
        
        for group in groups {
            // 获取 group 的 page
            let groupPage = try LaunchpadExporter.fetchPages(db: db, parentId: group)[0]
            let groupItems = try LaunchpadExporter.fetchPageItems(db: db, pageId: groupPage.itemId) // 获取 group page 下 item
            if groupItems.isEmpty {
                // delete group page item
                try deleteGroup(db: db, itemId: groupPage.itemId)
                try deleteItem(db: db, itemId: groupPage.itemId)
                // delete group item
                try deleteGroup(db: db, itemId: group)
                try deleteItem(db: db, itemId: group)
            }
        }
        
        // kill dock 后，会自动清理，删除所有空page会有问题（原因暂未分析）
//        let pages = try LaunchpadExporter.fetchPages(db: db, parentId: 1)
//        for page in pages {
//            let items = try LaunchpadExporter.fetchPageItems(db: db, pageId: page.itemId)
//            if items.isEmpty {
//                print(page, items)
//                delete page item
//                try deleteItem(db: db, itemId: page.itemId)
//            }
//        }
    }
    
    private static func fetchGroups(db: OpaquePointer?) throws -> [Int32] {
        let sql = """
        SELECT rowid FROM items
        WHERE flags is not null AND type = 2
        ORDER BY ordering
        """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        defer { sqlite3_finalize(statement) }
        
        var groups = [Int32]()
        while sqlite3_step(statement) == SQLITE_ROW {
            let itemId = sqlite3_column_int(statement, 0) // id
            groups.append(itemId)
        }
        return groups
    }
    
    private static func deleteItem(db: OpaquePointer?, itemId: Int32) throws {
        let sql = "DELETE FROM items WHERE rowid = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_int(statement, 1, itemId)
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
    }
    
    private static func deleteGroup(db: OpaquePointer?, itemId: Int32) throws {
        let sql = "DELETE FROM groups WHERE item_id = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_int(statement, 1, itemId)
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
    }
}
