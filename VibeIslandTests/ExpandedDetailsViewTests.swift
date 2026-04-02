//
//  ExpandedDetailsViewTests.swift
//  VibeIslandTests
//
//  ExpandedDetailsView UI 测试
//

import XCTest
import SwiftUI
@testable import VibeIsland

final class ExpandedDetailsViewTests: XCTestCase {
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

    // MARK: - Expanded View Tests

    func testExpandedViewWithNoAgents() {
        // TODO: 实现测试
        // 验证空状态正确显示
    }

    func testExpandedViewWithAgents() {
        // TODO: 实现测试
        // 验证所有代理正确显示在列表中
    }

    func testExpandedViewScroll() {
        // TODO: 实现测试
        // 验证多个代理时滚动功能正常
    }

    func testExpandedViewAgentCardLayout() {
        // TODO: 实现测试
        // 验证代理卡片布局正确
    }
}