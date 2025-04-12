import Foundation

//
//  苹果应用默认布局信息，暂时用不到
//
//  MainPageLayout.swift
//  LaunchpadManager
//
//  Created by 陈飞 on 2025/4/12.
//
class MainPageLayout {
    
    enum MainPageLayoutLoadError: Error {
        case fileNotFound
        case invalidPlistStructure
        case parsingFailed(Error)
    }
    
    private let filePath = "/System/Library/CoreServices/Dock.app/Contents/Resources/LaunchPadLayout.plist"
    
    private var mainPageApps: [[String: Any]] = []

    
    // 初始化时自动加载数据
    init() throws {
        try loadLaunchPadData()
    }
    
    /// 加载并解析 plist 文件
    private func loadLaunchPadData() throws {
        guard let plistData = FileManager.default.contents(atPath: filePath) else {
            throw MainPageLayoutLoadError.fileNotFound
        }
        
        do {
            let plist = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
            
            guard let plistDict = plist as? [String: Any],
                  let launchpad = plistDict["launchpad"] as? [String: Any],
                  let layout = launchpad["layout"] as? [String: Any],
                  let mainPage = layout["mainPage"] as? [[String: Any]] else {
                throw MainPageLayoutLoadError.invalidPlistStructure
            }
            
            self.mainPageApps = mainPage
        } catch {
            throw MainPageLayoutLoadError.parsingFailed(error)
        }
    }
    
    /// 获取 mainPage 应用列表（使用缓存数据）
    func getMainPageApps() -> [[String: Any]] {
        return mainPageApps
    }
    
    /// 重新加载数据（强制刷新）
    func reloadData() throws {
        try loadLaunchPadData()
    }
}
