//
//  StateManagerTests.swift
//  VibeIslandTests
//
//  状态管理器测试
//

import XCTest
import Combine
@testable import VibeIsland

@available(macOS 14.0, *)
final class StateManagerTests: XCTestCase {

    var stateManager: StateManager!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        stateManager = StateManager.shared
        cancellables = Set<AnyCancellable>()

        // 清理所有状态以确保测试隔离
        stateManager.removeAllAgentStates()
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        stateManager.removeAllAgentStates()
        stateManager = nil
    }

    // MARK: - 状态变化检测测试

    func testStateChangeDetection() throws {
        // 创建初始状态
        let initialState = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        // 更新状态
        var notificationReceived = false
        var receivedAgentId: String?
        var receivedOldStatus: String?
        var receivedNewStatus: String?

        let expectation = self.expectation(description: "状态变化通知")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { notification in
            notificationReceived = true
            receivedAgentId = notification.userInfo?["agentId"] as? String
            receivedOldStatus = notification.userInfo?["oldStatus"] as? String
            receivedNewStatus = notification.userInfo?["newStatus"] as? String
            expectation.fulfill()
        }

        stateManager.updateAgentState(initialState)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        // 验证新代理触发通知
        XCTAssertTrue(notificationReceived, "新代理应该触发状态变化通知")
        XCTAssertEqual(receivedAgentId, "agent1", "代理ID应该匹配")
        XCTAssertNil(receivedOldStatus, "旧状态应该为nil（新代理）")
        XCTAssertEqual(receivedNewStatus, "inProgress", "新状态应该匹配")
    }

    func testNoChangeFromSameState() throws {
        // 创建初始状态
        let initialState = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        // 更新状态
        stateManager.updateAgentState(initialState)

        // 等待第一个通知
        Thread.sleep(forTimeInterval: 0.1)

        // 记录通知计数
        var notificationCount = 0

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
        }

        // 再次更新相同状态
        let sameState = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(sameState)

        // 等待并验证没有新通知
        Thread.sleep(forTimeInterval: 0.1)

        NotificationCenter.default.removeObserver(observer)

        XCTAssertEqual(notificationCount, 0, "相同状态不应该触发新通知")
    }

    func testStateTransitionTriggersNotification() throws {
        // 创建初始状态
        let initialState = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(initialState)

        Thread.sleep(forTimeInterval: 0.1)

        // 监听状态变化
        var notificationReceived = false
        var receivedOldStatus: String?
        var receivedNewStatus: String?

        let expectation = self.expectation(description: "状态转换通知")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { notification in
            notificationReceived = true
            receivedOldStatus = notification.userInfo?["oldStatus"] as? String
            receivedNewStatus = notification.userInfo?["newStatus"] as? String
            expectation.fulfill()
        }

        // 更新到完成状态
        let completedState = AgentState(
            id: "agent1",
            status: .complete,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(completedState)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        // 验证状态转换触发通知
        XCTAssertTrue(notificationReceived, "状态转换应该触发通知")
        XCTAssertEqual(receivedOldStatus, "inProgress", "旧状态应该正确")
        XCTAssertEqual(receivedNewStatus, "complete", "新状态应该正确")
    }

    // MARK: - 上一个状态追踪测试

    func testLastAgentStatesTracking() throws {
        let agent1 = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(agent1)

        // 验证上一个状态被追踪
        let lastStatus = stateManager.getLastAgentStatus("agent1")
        XCTAssertEqual(lastStatus, .inProgress, "应该追踪上一个状态")

        // 更新状态
        let completedState = AgentState(
            id: "agent1",
            status: .complete,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(completedState)

        // 验证上一个状态已更新
        let newLastStatus = stateManager.getLastAgentStatus("agent1")
        XCTAssertEqual(newLastStatus, .complete, "上一个状态应该已更新")
    }

    func testDidAgentStatusChange() throws {
        let agent1 = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        // 新代理应该被视为状态变化
        XCTAssertTrue(
            stateManager.didAgentStatusChange("agent1", newStatus: .inProgress),
            "新代理应该被视为状态变化"
        )

        // 更新状态
        stateManager.updateAgentState(agent1)

        // 相同状态不应该被视为变化
        XCTAssertFalse(
            stateManager.didAgentStatusChange("agent1", newStatus: .inProgress),
            "相同状态不应该被视为变化"
        )

        // 不同状态应该被视为变化
        XCTAssertTrue(
            stateManager.didAgentStatusChange("agent1", newStatus: .complete),
            "不同状态应该被视为变化"
        )
    }

    // MARK: - 批量更新测试

    func testBatchUpdateWithMixedChanges() throws {
        let agents = [
            AgentState(id: "agent1", status: .inProgress, terminalAppBundleId: "com.apple.terminal"),
            AgentState(id: "agent2", status: .complete, terminalAppBundleId: "com.apple.terminal"),
            AgentState(id: "agent3", status: .awaitingApproval, terminalAppBundleId: "com.apple.terminal")
        ]

        var notificationReceived = false
        let expectation = self.expectation(description: "批量更新通知")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStatesDidChange,
            object: nil,
            queue: .main
        ) { notification in
            notificationReceived = true
            if let count = notification.userInfo?["count"] as? Int {
                XCTAssertEqual(count, 3, "批量更新应该包含正确数量的代理")
            }
            expectation.fulfill()
        }

        stateManager.updateAgentStates(agents)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertTrue(notificationReceived, "批量更新应该触发通知")

        // 验证所有代理都已添加
        XCTAssertEqual(stateManager.getAgentCount(for: .inProgress), 1)
        XCTAssertEqual(stateManager.getAgentCount(for: .complete), 1)
        XCTAssertEqual(stateManager.getAgentCount(for: .awaitingApproval), 1)
    }

    func testBatchUpdateDetectsChanges() throws {
        // 添加初始代理
        let initialAgent = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(initialAgent)

        Thread.sleep(forTimeInterval: 0.1)

        // 批量更新（包含状态变化）
        let agents = [
            AgentState(id: "agent1", status: .complete, terminalAppBundleId: "com.apple.terminal"), // 状态变化
            AgentState(id: "agent2", status: .inProgress, terminalAppBundleId: "com.apple.terminal")  // 新代理
        ]

        var notificationReceived = false
        var hasChanges = false

        let expectation = self.expectation(description: "批量更新通知")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStatesDidChange,
            object: nil,
            queue: .main
        ) { notification in
            notificationReceived = true
            hasChanges = notification.userInfo?["hasChanges"] as? Bool ?? false
            expectation.fulfill()
        }

        stateManager.updateAgentStates(agents)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertTrue(notificationReceived, "批量更新应该触发通知")
        XCTAssertTrue(hasChanges, "批量更新应该检测到变化")
    }

    // MARK: - 状态查询测试

    func testGetAgentState() throws {
        let agent1 = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(agent1)

        let retrievedState = stateManager.getAgentState(id: "agent1")
        XCTAssertNotNil(retrievedState, "应该能够检索代理状态")
        XCTAssertEqual(retrievedState?.id, "agent1", "代理ID应该匹配")
        XCTAssertEqual(retrievedState?.status, .inProgress, "状态应该匹配")
    }

    func testGetNonExistentAgent() throws {
        let retrievedState = stateManager.getAgentState(id: "nonexistent")
        XCTAssertNil(retrievedState, "不应该能够检索不存在的代理")
    }

    func testGetAgentCount() throws {
        XCTAssertEqual(stateManager.getAgentCount(for: .inProgress), 0)

        let agents = [
            AgentState(id: "agent1", status: .inProgress, terminalAppBundleId: "com.apple.terminal"),
            AgentState(id: "agent2", status: .inProgress, terminalAppBundleId: "com.apple.terminal"),
            AgentState(id: "agent3", status: .complete, terminalAppBundleId: "com.apple.terminal")
        ]

        stateManager.updateAgentStates(agents)

        XCTAssertEqual(stateManager.getAgentCount(for: .inProgress), 2)
        XCTAssertEqual(stateManager.getAgentCount(for: .complete), 1)
        XCTAssertEqual(stateManager.getAgentCount(for: .awaitingApproval), 0)
    }

    func testHasAwaitingApprovalAgents() throws {
        XCTAssertFalse(stateManager.hasAwaitingApprovalAgents(), "初始时不应该有待审批的代理")

        let agent = AgentState(
            id: "agent1",
            status: .awaitingApproval,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(agent)

        XCTAssertTrue(stateManager.hasAwaitingApprovalAgents(), "应该检测到有待审批的代理")
    }

    // MARK: - 状态移除测试

    func testRemoveAgentState() throws {
        let agent1 = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(agent1)

        var notificationReceived = false
        var removedAgentId: String?

        let expectation = self.expectation(description: "代理移除通知")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidRemove,
            object: nil,
            queue: .main
        ) { notification in
            notificationReceived = true
            removedAgentId = notification.userInfo?["agentId"] as? String
            expectation.fulfill()
        }

        stateManager.removeAgentState(id: "agent1")

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertTrue(notificationReceived, "移除代理应该触发通知")
        XCTAssertEqual(removedAgentId, "agent1", "移除的代理ID应该匹配")
        XCTAssertNil(stateManager.getAgentState(id: "agent1"), "代理应该被移除")
    }

    func testRemoveAllAgentStates() throws {
        let agents = [
            AgentState(id: "agent1", status: .inProgress, terminalAppBundleId: "com.apple.terminal"),
            AgentState(id: "agent2", status: .complete, terminalAppBundleId: "com.apple.terminal")
        ]

        stateManager.updateAgentStates(agents)

        var notificationReceived = false

        let expectation = self.expectation(description: "全部清空通知")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStatesDidClear,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }

        stateManager.removeAllAgentStates()

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertTrue(notificationReceived, "清空所有代理应该触发通知")
        XCTAssertEqual(stateManager.getAgentStates().count, 0, "所有代理应该被清空")
    }

    // MARK: - 单例测试

    func testSingleton() throws {
        let instance1 = StateManager.shared
        let instance2 = StateManager.shared

        XCTAssertTrue(instance1 === instance2, "StateManager 应该是单例")
    }
}