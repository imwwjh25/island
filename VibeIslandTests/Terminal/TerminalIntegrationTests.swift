//
//  TerminalIntegrationTests.swift
//  VibeIslandTests
//
//  终端集成测试
//

import XCTest
@testable import VibeIsland

final class TerminalIntegrationTests: XCTestCase {
    var controller: TerminalController!

    override func setUp() {
        super.setUp()
        controller = TerminalController.shared
    }

    override func tearDown() {
        controller = nil
        super.tearDown()
    }

    // MARK: - 多终端场景测试

    func testMultipleTerminalsSimultaneously() {
        // 测试同时处理多个终端应用
        let iterm2Running = controller.isTerminalRunning(.iterm2)
        let terminalRunning = controller.isTerminalRunning(.terminal)

        // 至少验证方法调用不会崩溃
        XCTAssertNoThrow(controller.isTerminalRunning(.iterm2))
        XCTAssertNoThrow(controller.isTerminalRunning(.terminal))
    }

    // MARK: - 边界条件测试

    func testJumpToTabWithSpecialCharacters() {
        // 测试包含特殊字符的标签页 ID
        let specialTabIds = ["test-123", "test_tab", "test.tab", "测试标签"]
        for tabId in specialTabIds {
            XCTAssertNoThrow(controller.jumpToTab(terminal: .iterm2, tabId: tabId))
        }
    }

    func testJumpToTabWithNilTabId() {
        // 测试空字符串处理
        XCTAssertFalse(controller.jumpToTab(terminal: .iterm2, tabId: ""))
    }

    // MARK: - 性能测试

    func testTerminalDetectionPerformance() {
        measure {
            _ = controller.isTerminalRunning(.iterm2)
        }
    }

    func testJumpToTabPerformance() {
        measure {
            _ = controller.jumpToTab(terminal: .iterm2, tabId: "test")
        }
    }
}