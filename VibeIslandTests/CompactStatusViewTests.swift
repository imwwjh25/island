//
//  CompactStatusViewTests.swift
//  VibeIslandTests
//
//  CompactStatusView UI 测试
//

import XCTest
import SwiftUI
@testable import VibeIsland

final class CompactStatusViewTests: XCTestCase {
    var stateManager: StateManager?

    override func setUp() {
        super.setUp()
        stateManager = StateManager.shared
        stateManager?.agentStates = []
    }

    override func tearDown() {
        stateManager?.agentStates = []
        super.tearDown()
    }

    // MARK: - Compact View Tests

    func testCompactViewWithNoAgents() {
        // TODO: 实现测试
        // 验证无代理时显示正确图标
    }

    func testCompactViewWithActiveAgents() {
        // TODO: 实现测试
        // 验证有活跃代理时显示状态圆点和数量徽章
    }

    func testCompactViewStatusIndicatorColors() {
        // TODO: 实现测试
        // 验证不同状态显示正确颜色
    }

    func testCompactViewBadgeCount() {
        // TODO: 实现测试
        // 验证徽章数量正确
    }
}