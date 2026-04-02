//
//  TerminalControllerTests.swift
//  VibeIslandTests
//
//  TerminalController 单元测试
//

import XCTest
@testable import VibeIsland

final class TerminalControllerTests: XCTestCase {
    var controller: TerminalController!

    override func setUp() {
        super.setUp()
        controller = TerminalController.shared
    }

    override func tearDown() {
        controller = nil
        super.tearDown()
    }

    // MARK: - TerminalType 测试

    func testTerminalTypeIterm2BundleId() {
        XCTAssertEqual(TerminalType.iterm2.rawValue, "com.googlecode.iterm2")
    }

    func testTerminalTypeTerminalBundleId() {
        XCTAssertEqual(TerminalType.terminal.rawValue, "com.apple.terminal")
    }

    func testTerminalTypeIterm2DisplayName() {
        XCTAssertEqual(TerminalType.iterm2.displayName, "iTerm2")
    }

    func testTerminalTypeTerminalDisplayName() {
        XCTAssertEqual(TerminalType.terminal.displayName, "Terminal.app")
    }

    func testTerminalTypeAllCases() {
        XCTAssertEqual(TerminalType.allCases.count, 2)
        XCTAssertTrue(TerminalType.allCases.contains(.iterm2))
        XCTAssertTrue(TerminalType.allCases.contains(.terminal))
    }

    // MARK: - isTerminalRunning 测试

    func testIsTerminalRunningIterm2Running() {
        // 检查 iTerm2 是否运行（如果未运行则跳过）
        let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: TerminalType.iterm2.rawValue).isEmpty == false
        if isRunning {
            XCTAssertTrue(controller.isTerminalRunning(.iterm2))
        }
    }

    func testIsTerminalRunningIterm2NotRunning() {
        // 确保使用不存在的 Bundle ID 返回 false
        XCTAssertFalse(controller.isTerminalRunning(.iterm2) || !NSRunningApplication.runningApplications(withBundleIdentifier: TerminalType.iterm2.rawValue).isEmpty)
    }

    func testIsTerminalRunningTerminalRunning() {
        let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: TerminalType.terminal.rawValue).isEmpty == false
        if isRunning {
            XCTAssertTrue(controller.isTerminalRunning(.terminal))
        }
    }

    func testIsTerminalRunningTerminalNotRunning() {
        XCTAssertFalse(controller.isTerminalRunning(.terminal) || !NSRunningApplication.runningApplications(withBundleIdentifier: TerminalType.terminal.rawValue).isEmpty)
    }

    // MARK: - jumpToTab 测试

    func testJumpToTabIterm2NotRunning() {
        let result = controller.jumpToTab(terminal: .iterm2, tabId: "test-tab")
        // 如果 iTerm2 未运行，应返回 false
        if !controller.isTerminalRunning(.iterm2) {
            XCTAssertFalse(result)
        }
    }

    func testJumpToTabTerminalNotRunning() {
        let result = controller.jumpToTab(terminal: .terminal, tabId: "test-tab")
        // 如果 Terminal.app 未运行，应返回 false
        if !controller.isTerminalRunning(.terminal) {
            XCTAssertFalse(result)
        }
    }

    func testJumpToTabInvalidTabId() {
        // 测试无效标签页 ID 的处理
        let result = controller.jumpToTab(terminal: .iterm2, tabId: "")
        XCTAssertFalse(result)
    }
}