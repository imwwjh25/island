//
//  MockTerminalController.swift
//  VibeIslandTests
//
//  模拟终端控制器
//

import Foundation
@testable import VibeIsland

/// 模拟终端控制器，用于测试
class MockTerminalController {
    /// 模拟的终端运行状态
    var isIterm2Running = false
    var isTerminalAppRunning = false

    /// 模拟的跳转结果
    var jumpToTabResult = true

    /// 模拟的 AppleScript 执行器
    let mockExecutor = MockAppleScriptExecutor()

    /// 检查终端是否运行（模拟）
    func isTerminalRunning(_ type: TerminalType) -> Bool {
        switch type {
        case .iterm2:
            return isIterm2Running
        case .terminal:
            return isTerminalAppRunning
        }
    }

    /// 跳转到标签页（模拟）
    func jumpToTab(terminal type: TerminalType, tabId: String) -> Bool {
        if !isTerminalRunning(type) {
            return false
        }
        return jumpToTabResult
    }

    /// 重置模拟状态
    func reset() {
        isIterm2Running = false
        isTerminalAppRunning = false
        jumpToTabResult = true
        mockExecutor.reset()
    }
}