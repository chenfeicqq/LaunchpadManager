//
//  LaunchpadLayout.swift
//  LaunchpadManager
//
//  Created by 陈飞 on 2025/4/12.
//
//  结构示例
//    [
//      {
//        "type": "page",
//        "order": 1,
//        "items": [
//          {
//            "type": "app",
//            "order": 1,
//            "title": "Safari",
//            "bundleid": "com.apple.Safari"
//          },
//          {
//            "type": "group",
//            "order": 2,
//            "title": "Development",
//            "items": [
//              {
//                "type": "app",
//                "order": 1,
//                "title": "Xcode",
//                "bundleid": "com.apple.Xcode"
//              }
//            ]
//          }
//        ]
//      }
//    ]
struct LaunchpadLayout: Codable {
    
    struct Item: Codable {
        let type: String // page | group | app
        let order: Int
        let title: String? // group | app
        let bundleid: String? // app
        var items: [Item]? // page | group
        
        init(type: String, order: Int, title: String?, bundleid: String?, items: [Item]?) {
            self.type = type
            self.order = order
            self.title = title
            self.bundleid = bundleid
            self.items = items
        }
        
        init(order: Int, items: [Item]) {
            self.init(
                type: "page",
                order: order,
                title: nil,
                bundleid: nil,
                items: items
            )
        }
        
        init(order: Int, title: String, items: [Item]) {
            self.init(
                type: "group",
                order: order,
                title: title,
                bundleid: nil,
                items: items
            )
        }
        
        init(order: Int, title: String, bundleid: String) {
            self.init(
                type: "app",
                order: order,
                title: title,
                bundleid: bundleid,
                items: nil
            )
        }
    }

    var pages: [Item]
    
    mutating func append(_ page: Item) {
        self.pages.append(page)
    }
}
