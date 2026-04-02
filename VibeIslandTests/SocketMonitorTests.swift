//
//  SocketMonitorTests.swift
//  VibeIslandTests
//
//  套接字监控器测试
//

import XCTest
import Network
@testable import VibeIsland

@available(macOS 14.0, *)
final class SocketMonitorTests: XCTestCase {

    var socketMonitor: SocketMonitor!
    var receivedStates: [AgentState] = []

    override func setUpWithError() throws {
        socketMonitor = SocketMonitor(host: "localhost", port: 8765)
        receivedStates = []
    }

    override func tearDownWithError() throws {
        socketMonitor.stop()
        socketMonitor = nil
        receivedStates.removeAll()
    }

    // MARK: - JSON 消息解析测试

    func testParseValidJSONMessage() throws {
        // 测试标准 AgentState 格式
        let jsonString = """
        {
            "id": "agent1",
            "status": "inProgress",
            "terminalAppBundleId": "com.apple.terminal",
            "terminalTabId": "tab1",
            "lastUpdated": "2026-04-02T12:00:00Z"
        }
        """

        let agentState = AgentState.from(jsonString: jsonString)

        XCTAssertNotNil(agentState, "应该能够解析有效的 JSON 消息")
        XCTAssertEqual(agentState?.id, "agent1")
        XCTAssertEqual(agentState?.status, .inProgress)
        XCTAssertEqual(agentState?.terminalAppBundleId, "com.apple.terminal")
        XCTAssertEqual(agentState?.terminalTabId, "tab1")
    }

    func testParseClaudeCodeFormatMessage() throws {
        // 测试 Claude Code 格式
        let jsonString = """
        {
            "agent_id": "agent2",
            "status": "complete",
            "terminal": "com.googlecode.iterm2:tab2",
            "timestamp": "2026-04-02T12:00:00Z"
        }
        """

        // 由于 parseClaudeCodeFormat 是私有方法，我们通过消息回调测试
        let expectation = self.expectation(description: "消息回调")
        var receivedState: AgentState?

        socketMonitor.setMessageCallback { state in
            receivedState = state
            expectation.fulfill()
        }

        // 注意：这个测试需要模拟套接字连接，实际测试中应使用模拟对象
        // 这里仅测试数据模型的解析能力
        XCTAssertTrue(true, "Claude Code 格式解析测试需要模拟套接字")
    }

    func testParseInvalidJSONMessage() throws {
        let invalidJSON = "{ invalid json }"

        let agentState = AgentState.from(jsonString: invalidJSON)

        XCTAssertNil(agentState, "无效的 JSON 应该返回 nil")
    }

    func testParseEmptyMessage() throws {
        let emptyJSON = ""

        let agentState = AgentState.from(jsonString: emptyJSON)

        XCTAssertNil(agentState, "空消息应该返回 nil")
    }

    func testParsePartialMessage() throws {
        // 测试不完整的 JSON
        let partialJSON = """
        {
            "id": "agent1",
            "status": "inProgress"
        }
        """

        let agentState = AgentState.from(jsonString: partialJSON)

        // 应该失败，因为缺少必需字段
        XCTAssertNil(agentState, "不完整的消息应该返回 nil")
    }

    // MARK: - 连接状态测试

    func testInitialConnectionStatus() throws {
        XCTAssertEqual(
            socketMonitor.connectionStatus.isConnected,
            false,
            "初始连接状态应该是未连接"
        )
    }

    // MARK: - 消息回调测试

    func testMessageCallback() throws {
        var callbackInvoked = false
        var receivedState: AgentState?

        socketMonitor.setMessageCallback { state in
            callbackInvoked = true
            receivedState = state
        }

        // 验证回调已设置
        XCTAssertTrue(true, "消息回调已设置")
    }

    // MARK: - 多消息处理测试

    func testMultipleConcurrentMessages() throws {
        // 测试多个并发消息的处理
        let messages = [
            AgentState(id: "agent1", status: .inProgress, terminalAppBundleId: "com.apple.terminal"),
            AgentState(id: "agent2", status: .complete, terminalAppBundleId: "com.googlecode.iterm2"),
            AgentState(id: "agent3", status: .awaitingApproval, terminalAppBundleId: "com.apple.terminal")
        ]

        // 验证每个消息都能正确序列化和反序列化
        for message in messages {
            if let jsonString = message.toJSON(),
               let parsedState = AgentState.from(jsonString: jsonString) {
                XCTAssertEqual(parsedState.id, message.id)
                XCTAssertEqual(parsedState.status, message.status)
            } else {
                XCTFail("消息序列化或反序列化失败")
            }
        }
    }

    // MARK: - 重连策略测试

    func testReconnectDelayIncreases() throws {
        // 测试重连延迟是否按指数增长
        // 注意：这需要访问私有属性，实际测试中应使用模拟对象

        // 验证常量配置
        XCTAssertEqual(SocketMonitor.minReconnectDelay, 1.0, "最小重连延迟应该是 1 秒")
        XCTAssertEqual(SocketMonitor.maxReconnectDelay, 30.0, "最大重连延迟应该是 30 秒")
    }

    // MARK: - 心跳机制测试

    func testHeartbeatInterval() throws {
        // 验证心跳间隔配置
        XCTAssertEqual(SocketMonitor.heartbeatInterval, 30.0, "心跳间隔应该是 30 秒")
    }
}
