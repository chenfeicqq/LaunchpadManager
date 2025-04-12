//
//  LaunchpadManagerApp.swift
//  LaunchpadManager
//
//  Created by 陈飞 on 2025/3/10.
//

import SwiftUI

@main
struct LaunchpadManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // 添加帮助菜单
            CommandGroup(replacing: .help) {
                Button("Github page") {
                    if let url = URL(string: "https://github.com/chenfeicqq/LaunchpadManager") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("?", modifiers: [.command])
            }
        }
    }
}
