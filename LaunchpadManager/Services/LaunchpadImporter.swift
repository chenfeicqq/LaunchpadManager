//
//  LaunchpadImporter.swift
//  LaunchpadManager
//
//  Created by 陈飞 on 2025/4/12.
//

import Foundation
import SQLite3

class LaunchpadImporter {
    
    static func importLayout(data: Data) throws {
        
        let dbPath = try LaunchpadDB.getDBPath()
        
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 1, userInfo: nil)
        }
        
        defer { sqlite3_close(db) }
        
        let pages = try JSONDecoder().decode([LaunchpadLayout.Item].self, from: data).sorted { $0.order < $1.order }
        
        for page in pages {
            let pageId = try createPage(db: db)
            try pushItems(db: db, parentId: pageId, items: page.items)
        }
    }
    
    private static func pushItems(db: OpaquePointer?, parentId: Int64, items: [LaunchpadLayout.Item]?) throws {
        for item in items ?? [] {
            switch item.type {
            case "group":
                // 创建分组
                let groupPageId = try createGroup(db: db, title: item.title, parentId: parentId)
                // 递归处理分组下 items
                try pushItems(db: db, parentId: groupPageId, items: item.items)
            case "app":
                try pushApp(db: db, parentId: parentId, item: item)
            default: continue
            }
        }
    }
    
    private static func pushApp(db: OpaquePointer?, parentId: Int64, item: LaunchpadLayout.Item) throws {
        if let itemId = try findItem(db: db, bundleid: item.bundleid!){
            // 更新 parent
            try updateItemParent(db: db, itemId: itemId, parentId: parentId)
            
            // 更新 order
            try updateItemOrder(db: db, itemId: itemId, order: Int32(item.order))
        }
    }
    
    private static func findItem(db: OpaquePointer?, bundleid: String) throws -> Int64? {
        let sql = "SELECT item_id FROM apps WHERE bundleid = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_text(statement, 1, (bundleid as NSString).utf8String, -1, nil)
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return sqlite3_column_int64(statement, 0)
    }
    
    private static func updateItemParent(db: OpaquePointer?, itemId: Int64, parentId: Int64) throws {
        let sql = "UPDATE items SET parent_id = ? WHERE rowid = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_int64(statement, 1, parentId)
        sqlite3_bind_int64(statement, 2, itemId)
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
    }
    
    private static func updateItemOrder(db: OpaquePointer?, itemId: Int64, order: Int32) throws {
        let sql = "UPDATE items SET ordering = ? WHERE rowid = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_int(statement, 1, order)
        sqlite3_bind_int64(statement, 2, itemId)
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
    }
    
    private static func createGroup(db: OpaquePointer?, title: String?, parentId: Int64) throws -> Int64 {
        let groupId = try createItem(db: db, type: 2, parentId: parentId)
        try createGroup(db: db, itemId: groupId, title: title)
        
        let groupPageId = try createItem(db: db, type: 3, parentId: groupId)
        try createGroup(db: db, itemId: groupPageId, title: nil)
        
        return groupPageId;
    }
    
    private static func createPage(db: OpaquePointer?) throws -> Int64 {
        let pageId = try createItem(db: db, type: 3, parentId: 1)
        try createGroup(db: db, itemId: pageId, title: nil)
        return pageId
    }
    
    private static func createGroup(db: OpaquePointer?, itemId: Int64, title: String?) throws {
        let sql = """
        INSERT INTO groups
        (item_id, title)
        VALUES
        (?, ?)
        """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_int64(statement, 1, itemId)
        if let title {
            sqlite3_bind_text(statement, 2, (title as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 2)
        }
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
    }
    
    private static func createItem(db: OpaquePointer?, type: Int32, parentId: Int64) throws -> Int64 {
        let sql = """
        INSERT INTO items
        (uuid, flags, type, parent_id)
        VALUES
        (?, 0, ?, ?)
        """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_text(statement, 1, (UUID().uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, type)
        sqlite3_bind_int64(statement, 3, parentId)
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        return sqlite3_last_insert_rowid(db)
    }
}
