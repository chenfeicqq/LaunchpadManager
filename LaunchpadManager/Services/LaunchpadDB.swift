import Foundation
import AppKit

//
//  LaunchpadDB.swift
//  LaunchpadManager
//
//  Created by 陈飞 on 2025/4/12.
//
public struct LaunchpadDB {

    public static func getDBPath() throws -> String {
        let command = "echo /private$(getconf DARWIN_USER_DIR)com.apple.dock.launchpad/db/db"
        return try safeShell(command).trimmingCharacters(in: .newlines)
    }
    
    public static func killDock() throws {
        try Self.safeShell("killall Dock")
    }
    
    public static func showInFinder() throws {
        let path = try getDBPath()
        let pathURL = URL(fileURLWithPath: path, isDirectory: true)
        // 使用 NSWorkspace 打开 Finder
        NSWorkspace.shared.activateFileViewerSelecting([pathURL])
    }

    @discardableResult
    static func safeShell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil

        try task.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }
}
