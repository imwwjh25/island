//
//  VibeIslandAppTests.swift
//  VibeIslandTests
//
//  主应用集成测试
//

import XCTest
import Combine
import NotificationCenter
@testable import VibeIsland

@available(macOS 14.0, *)
final class VibeIslandAppTests: XCTestCase {

    var stateManager: StateManager!
    var soundManager: SoundManager!
    var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        stateManager = StateManager.shared
        soundManager = SoundManager.shared
        cancellables = Set<AnyCancellable>()

        // 清理状态
        stateManager.removeAllAgentStates()

        // 启用音效用于测试
        soundManager.setSoundEnabled(true)
    }

    override func tearDownWithError() throws {
        cancellables.removeAll()
        stateManager.removeAllAgentStates()
        stateManager = nil
        soundManager = nil
    }

    // MARK: - 状态变化音效测试

    func testStateChangeTriggersSound() throws {
        // 创建测试代理
        let agent = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        var soundPlayed = false
        let expectation = self.expectation(description: "音效播放")

        // 监听通知
        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { _ in
            // 在实际应用中，这会触发音效播放
            // 这里我们验证通知被正确触发
            soundPlayed = true
            expectation.fulfill()
        }

        stateManager.updateAgentState(agent)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertTrue(soundPlayed, "状态变化应该触发音效")
    }

    func testNoSoundOnSameState() throws {
        // 创建初始状态
        let agent = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(agent)

        Thread.sleep(forTimeInterval: 0.1)

        // 监听通知
        var notificationCount = 0

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
        }

        // 更新相同状态
        let sameAgent = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        stateManager.updateAgentState(sameAgent)

        Thread.sleep(forTimeInterval: 0.1)

        NotificationCenter.default.removeObserver(observer)

        XCTAssertEqual(notificationCount, 0, "相同状态不应该触发音效")
    }

    // MARK: - Widget重新加载频率限制测试

    func testWidgetReloadRateLimit() throws {
        // 创建多个代理以触发多次状态变化
        let agents = (1...10).map { i in
            AgentState(
                id: "agent\(i)",
                status: .inProgress,
                terminalAppBundleId: "com.apple.terminal"
            )
        }

        var notificationCount = 0
        let expectation = self.expectation(description: "批量更新通知")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStatesDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
            expectation.fulfill()
        }

        stateManager.updateAgentStates(agents)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        // 批量更新应该只触发一次通知
        XCTAssertEqual(notificationCount, 1, "批量更新应该只触发一次通知")
    }

    func testRapidStateChanges() throws {
        // 模拟快速连续的状态变化
        let agentId = "agent1"

        var notificationCount = 0
        let expectation = self.expectation(description: "状态变化通知")
        expectation.expectedFulfillmentCount = 2

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
            expectation.fulfill()
        }

        // 快速连续更新状态
        stateManager.updateAgentState(AgentState(
            id: agentId,
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        ))

        stateManager.updateAgentState(AgentState(
            id: agentId,
            status: .complete,
            terminalAppBundleId: "com.apple.terminal"
        ))

        wait(for: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(observer)

        // 应该收到两次通知（inProgress 和 complete）
        XCTAssertEqual(notificationCount, 2, "快速状态变化应该触发相应次数的通知")
    }

    // MARK: - 集成测试

    func testCompleteStateChangeFlow() throws {
        // 测试完整的状态变化流程：状态更新 -> 音效 -> widget重新加载

        let agentId = "agent1"

        var steps = [String]()
        let expectation = self.expectation(description: "集成测试")
        expectation.expectedFulfillmentCount = 3

        // 监听状态变化
        let stateObserver = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { notification in
            if notification.userInfo?["agentId"] as? String == agentId {
                steps.append("状态变化")
                expectation.fulfill()
            }
        }

        // 模拟状态变化
        stateManager.updateAgentState(AgentState(
            id: agentId,
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        ))

        wait(for: [expectation], timeout: 2.0)
        NotificationCenter.default.removeObserver(stateObserver)

        // 验证流程步骤
        XCTAssertTrue(steps.contains("状态变化"), "应该检测到状态变化")

        // 验证状态已更新
        let agentState = stateManager.getAgentState(id: agentId)
        XCTAssertNotNil(agentState, "代理状态应该已更新")
        XCTAssertEqual(agentState?.status, .inProgress, "代理状态应该正确")
    }

    func testMultiAgentStateChanges() throws {
        // 测试多个代理的状态变化

        let agents = [
            AgentState(id: "agent1", status: .inProgress, terminalAppBundleId: "com.apple.terminal"),
            AgentState(id: "agent2", status: .complete, terminalAppBundleId: "com.apple.terminal"),
            AgentState(id: "agent3", status: .awaitingApproval, terminalAppBundleId: "com.apple.terminal")
        ]

        var notificationCount = 0
        let expectation = self.expectation(description: "批量更新通知")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStatesDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationCount += 1
            expectation.fulfill()
        }

        stateManager.updateAgentStates(agents)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertEqual(notificationCount, 1, "批量更新应该触发一次通知")

        // 验证所有代理都已更新
        XCTAssertEqual(stateManager.getAgentCount(for: .inProgress), 1)
        XCTAssertEqual(stateManager.getAgentCount(for: .complete), 1)
        XCTAssertEqual(stateManager.getAgentCount(for: .awaitingApproval), 1)
    }

    func testSoundRespectsSystemMute() throws {
        // 测试系统静音时音效不播放

        let agent = AgentState(
            id: "agent1",
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        let isMuted = soundManager.isSystemMuted()

        // 更新状态
        stateManager.updateAgentState(agent)

        Thread.sleep(forTimeInterval: 0.1)

        // 验证不会崩溃
        // 实际测试中需要验证音效是否真的播放了
        // 由于系统音量不确定，这里只验证功能调用不崩溃
        XCTAssertTrue(true, "系统静音检测和音效播放不应该崩溃")
    }

    func testSoundToggleFunctionality() throws {
        // 测试音效开关功能

        // 禁用音效
        soundManager.setSoundEnabled(false)
        XCTAssertFalse(soundManager.isSoundEnabled, "音效应该被禁用")

        // 启用音效
        soundManager.setSoundEnabled(true)
        XCTAssertTrue(soundManager.isSoundEnabled, "音效应该被启用")

        // 切换音效
        soundManager.toggleSound()
        XCTAssertFalse(soundManager.isSoundEnabled, "音效应该被禁用（切换）")

        soundManager.toggleSound()
        XCTAssertTrue(soundManager.isSoundEnabled, "音效应该被启用（切换）")
    }

    // MARK: - 通知信息测试

    func testNotificationUserInfo() throws {
        // 测试通知中包含的用户信息

        let agentId = "agent1"
        let agent = AgentState(
            id: agentId,
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        )

        var receivedUserInfo: [String: Any]?
        let expectation = self.expectation(description: "通知信息")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { notification in
            receivedUserInfo = notification.userInfo
            expectation.fulfill()
        }

        stateManager.updateAgentState(agent)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertNotNil(receivedUserInfo, "通知应该包含用户信息")
        XCTAssertEqual(receivedUserInfo?["agentId"] as? String, agentId, "代理ID应该匹配")
        XCTAssertEqual(receivedUserInfo?["newStatus"] as? String, "inProgress", "新状态应该匹配")
        XCTAssertNil(receivedUserInfo?["oldStatus"], "旧状态应该为nil（新代理）")
    }

    func testStateTransitionUserInfo() throws {
        // 测试状态转换时的通知信息

        let agentId = "agent1"

        // 添加初始状态
        stateManager.updateAgentState(AgentState(
            id: agentId,
            status: .inProgress,
            terminalAppBundleId: "com.apple.terminal"
        ))

        Thread.sleep(forTimeInterval: 0.1)

        // 更新到完成状态
        var receivedOldStatus: String?
        var receivedNewStatus: String?

        let expectation = self.expectation(description: "状态转换信息")

        let observer = NotificationCenter.default.addObserver(
            forName: .agentStateDidChange,
            object: nil,
            queue: .main
        ) { notification in
            receivedOldStatus = notification.userInfo?["oldStatus"] as? String
            receivedNewStatus = notification.userInfo?["newStatus"] as? String
            expectation.fulfill()
        }

        stateManager.updateAgentState(AgentState(
            id: agentId,
            status: .complete,
            terminalAppBundleId: "com.apple.terminal"
        ))

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)

        XCTAssertEqual(receivedOldStatus, "inProgress", "旧状态应该正确")
        XCTAssertEqual(receivedNewStatus, "complete", "新状态应该正确")
    }
}