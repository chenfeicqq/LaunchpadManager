//
//  LaunchpadExporter.swift
//  LaunchpadManager
//
//  Created by 陈飞 on 2025/4/12.
//

import Foundation
import SQLite3

class LaunchpadExporter {
    
    static func exportLayout() throws -> Data {
        
        let dbPath = try LaunchpadDB.getDBPath()
        
        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        defer { sqlite3_close(db) }
        
        var layout = LaunchpadLayout(pages: [])
        
        // 查询所有根页面（parent_id=1）
        let pages = try fetchPages(db: db, parentId: 1)
        
        for page in pages {
            let pageItems = try fetchPageItems(db: db, pageId: page.itemId)
            layout.append(.init(
                order: page.order,
                items: pageItems
            ))
        }
        
        return try JSONEncoder().encode(layout.pages)
    }
    
    public static func fetchPages(db: OpaquePointer?, parentId: Int32) throws -> [(itemId: Int32, order: Int)] {
        let sql = """
        SELECT rowid, ordering FROM items
        WHERE flags is not null and parent_id = ? AND type = 3
        ORDER BY ordering
        """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_int(statement, 1, parentId)
        defer { sqlite3_finalize(statement) }
        
        var pages = [(Int32, Int)]()
        while sqlite3_step(statement) == SQLITE_ROW {
            let itemId = sqlite3_column_int(statement, 0) // id
            let order = Int(sqlite3_column_int(statement, 1)) // 排序
            pages.append((itemId, order))
        }
        return pages
    }
    
    public static func fetchPageItems(db: OpaquePointer?, pageId: Int32) throws -> [LaunchpadLayout.Item] {
        let sql = """
        SELECT i.rowid, i.type, a.title, a.bundleid, g.title, i.ordering
        FROM items i
        LEFT JOIN apps a ON i.rowid = a.item_id
        LEFT JOIN groups g ON i.rowid = g.item_id
        WHERE i.parent_id = ?
        ORDER BY i.ordering
        """
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteError", code: 501, userInfo: nil)
        }
        
        sqlite3_bind_int(statement, 1, pageId)
        defer { sqlite3_finalize(statement) }
        
        // 页面下的所有 item
        var items = [LaunchpadLayout.Item]()
        while sqlite3_step(statement) == SQLITE_ROW {
            let type = Int(sqlite3_column_int(statement, 1))
            let order = Int(sqlite3_column_int(statement, 5))
            switch type {
            case 2: // Group
                // 获取 group 的 page
                let groupPage = try fetchPages(db: db, parentId: sqlite3_column_int(statement, 0))[0]
                items.append(.init(
                    order: order,
                    title: String(cString: sqlite3_column_text(statement, 4)),
                    items: try fetchPageItems(db: db, pageId: groupPage.itemId) // 获取 group page 下 item
                ))
            case 4: // App
                items.append(.init(
                    order: order,
                    title: String(cString: sqlite3_column_text(statement, 2)),
                    bundleid: String(cString: sqlite3_column_text(statement, 3))
                ))
            default: continue
            }
        }
        return items
    }
}
