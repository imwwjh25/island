//
//  TerminalController.swift
//  VibeIsland
//
//  终端控制器 - 管理 iTerm2 和 Terminal.app 的标签页跳转
//

import AppKit

/// 终端类型枚举
enum TerminalType: String, CaseIterable {
    /// iTerm2
    case iterm2 = "com.googlecode.iterm2"
    /// Terminal.app
    case terminal = "com.apple.terminal"

    /// 获取终端的显示名称
    var displayName: String {
        switch self {
        case .iterm2:
            return "iTerm2"
        case .terminal:
            return "Terminal.app"
        }
    }

    /// 获取终端的应用名称（用于 AppleScript）
    var appName: String {
        switch self {
        case .iterm2:
            return "iTerm2"
        case .terminal:
            return "Terminal"
        }
    }
}

/// 终端控制器 - 单例模式
class TerminalController {
    /// 共享实例
    static let shared = TerminalController()

    /// 私有初始化方法（单例模式）
    private init() {}

    /// 跳转到指定的终端标签页
    /// - Parameters:
    ///   - type: 终端类型（iTerm2 或 Terminal.app）
    ///   - tabId: 标签页 ID（可以是标签页名称的一部分）
    /// - Returns: 是否跳转成功
    func jumpToTab(terminal type: TerminalType, tabId: String) -> Bool {
        // 首先检查终端应用是否运行
        guard isTerminalRunning(type) else {
            print("TerminalController: 终端应用 \(type.displayName) 未运行")
            return false
        }

        // 构造 AppleScript 命令
        let script: NSAppleScript?
        switch type {
        case .iterm2:
            script = createITerm2JumpScript(tabId: tabId)
        case .terminal:
            script = createTerminalJumpScript(tabId: tabId)
        }

        guard let appleScript = script else {
            print("TerminalController: 无法创建 AppleScript")
            return false
        }

        // 执行 AppleScript
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        if let error = error {
            print("TerminalController: AppleScript 执行失败 - \(error)")
            return false
        }

        print("TerminalController: 成功跳转到 \(type.displayName) 标签页 \(tabId)")
        return true
    }

    /// 检查终端应用是否运行
    /// - Parameter type: 终端类型
    /// - Returns: 是否运行
    func isTerminalRunning(_ type: TerminalType) -> Bool {
        let bundleId = type.rawValue
        let runningApps = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleId
        )
        return !runningApps.isEmpty
    }

    // MARK: - 私有方法

    /// 创建 iTerm2 跳转标签页的 AppleScript
    /// - Parameter tabId: 标签页 ID
    /// - Returns: NSAppleScript 实例
    private func createITerm2JumpScript(tabId: String) -> NSAppleScript {
        let scriptString = """
        tell application "iTerm2"
            tell current window
                set selected tab to tab whose name contains "\(tabId)"
            end tell
            activate
        end tell
        """
        return NSAppleScript(source: scriptString)
    }

    /// 创建 Terminal.app 跳转标签页的 AppleScript
    /// - Parameter tabId: 标签页 ID
    /// - Returns: NSAppleScript 实例
    private func createTerminalJumpScript(tabId: String) -> NSAppleScript {
        let scriptString = """
        tell application "Terminal"
            tell window 1
                set selected tab to tab whose name contains "\(tabId)"
            end tell
            activate
        end tell
        """
        return NSAppleScript(source: scriptString)
    }
}