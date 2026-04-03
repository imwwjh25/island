//
//  SocketMonitor.swift
//  VibeIsland
//
//  套接字监控和JSON消息解析
//

import Foundation
import Network
import Combine

/// 消息回调类型
typealias MessageCallback = (AgentState) -> Void

/// 连接状态枚举
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error(Error)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

/// 套接字监控器
/// 负责连接到 Claude Code 本地套接字并解析 JSON 消息
class SocketMonitor: ObservableObject {

    // MARK: - 常量

    /// 默认端口号
    static let defaultPort: UInt16 = 8765

    /// 默认主机地址
    static let defaultHost = "localhost"

    /// 心跳间隔（秒）
    static let heartbeatInterval: TimeInterval = 30

    /// 连接超时（秒）
    static let connectionTimeout: TimeInterval = 10

    /// 最大重连延迟（秒）
    static let maxReconnectDelay: TimeInterval = 30

    /// 最小重连延迟（秒）
    static let minReconnectDelay: TimeInterval = 1

    // MARK: - 属性

    /// 连接状态
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected

    /// 网络连接
    private var connection: NWConnection?

    /// 消息回调
    private var messageCallback: MessageCallback?

    /// 主队列
    private let queue = DispatchQueue(label: "com.vibeisland.socketmonitor")

    /// 心跳定时器
    private var heartbeatTimer: Timer?

    /// 重连定时器
    private var reconnectTimer: Timer?

    /// 当前重连延迟
    private var currentReconnectDelay: TimeInterval = 0

    /// 是否应该重连
    private var shouldReconnect = true

    /// 消息缓冲区
    private var messageBuffer = Data()

    /// 主机地址
    private let host: String

    /// 端口号
    private let port: UInt16

    // MARK: - 初始化

    /// 创建套接字监控器
    /// - Parameters:
    ///   - host: 主机地址
    ///   - port: 端口号
    init(host: String = SocketMonitor.defaultHost, port: UInt16 = SocketMonitor.defaultPort) {
        self.host = host
        self.port = port
    }

    // MARK: - 连接管理

    /// 启动套接字连接
    func start() {
        queue.async {
            self.shouldReconnect = true
            self.currentReconnectDelay = SocketMonitor.minReconnectDelay
            self.connect()
        }
    }

    /// 停止套接字连接
    func stop() {
        queue.async {
            self.shouldReconnect = false
            self.disconnect()
            self.cancelHeartbeat()
            self.cancelReconnect()
        }
    }

    /// 建立连接
    private func connect() {
        // 取消现有连接
        disconnect()

        // 更新状态
        DispatchQueue.main.async {
            self.connectionStatus = .connecting
        }

        print("🔌 正在连接到 \(host):\(port)...")

        // 创建主机端点
        let hostEndpoint = NWEndpoint.Host(host)
        guard let portEndpoint = NWEndpoint.Port(rawValue: port) else {
            handleConnectionError(SocketError.invalidPort)
            return
        }

        let endpoint = NWEndpoint.hostPort(host: hostEndpoint, port: portEndpoint)

        // 创建连接
        connection = NWConnection(
            to: endpoint,
            using: .tcp
        )

        // 配置连接
        connection?.pathUpdateHandler = { path in
            print("📍 网络路径更新: \(path)")
        }

        // 开始连接
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .ready:
                self.handleConnectionReady()
            case .failed(let error):
                self.handleConnectionError(error)
            case .waiting(let error):
                print("⏳ 连接等待中: \(error)")
            default:
                break
            }
        }

        // 启动连接队列
        connection?.start(queue: queue)
    }

    /// 断开连接
    private func disconnect() {
        connection?.cancel()
        connection = nil
    }

    /// 处理连接就绪
    private func handleConnectionReady() {
        DispatchQueue.main.async {
            self.connectionStatus = .connected
        }

        print("✅ 已连接到 Claude Code 套接字")

        // 重置重连延迟
        currentReconnectDelay = SocketMonitor.minReconnectDelay

        // 开始接收数据
        receiveData()

        // 启动心跳
        startHeartbeat()

        // 取消重连定时器
        cancelReconnect()
    }

    /// 处理连接错误
    private func handleConnectionError(_ error: Error) {
        DispatchQueue.main.async {
            self.connectionStatus = .error(error)
        }

        print("❌ 连接错误: \(error.localizedDescription)")

        disconnect()

        // 如果应该重连，安排重连
        if shouldReconnect {
            scheduleReconnect()
        }
    }

    // MARK: - 数据接收

    /// 接收数据
    private func receiveData() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }

            if let error = error {
                // 检查是否为 POSIX 错误 ECONNRESET（连接被重置）
                let nsError = error as NSError
                if nsError.domain != NSPOSIXErrorDomain || nsError.code != Int(POSIXError.ECONNRESET.rawValue) {
                    print("❌ 接收数据错误: \(error.localizedDescription)")
                }
                return
            }

            if let data = data, !data.isEmpty {
                self.processReceivedData(data)
            }

            // 继续接收
            if self.connectionStatus.isConnected {
                self.receiveData()
            }
        }
    }

    /// 处理接收到的数据
    private func processReceivedData(_ data: Data) {
        // 追加到缓冲区
        messageBuffer.append(data)

        // 尝试解析完整消息
        while let messageEnd = findMessageEnd(in: messageBuffer) {
            let messageData = messageBuffer.prefix(upTo: messageEnd)
            messageBuffer.removeFirst(messageEnd)

            // 解析消息
            if let messageString = String(data: messageData, encoding: .utf8) {
                parseMessage(messageString)
            }
        }
    }

    /// 查找消息结束位置（假设每条消息以换行符结束）
    private func findMessageEnd(in data: Data) -> Data.Index? {
        if let newlineIndex = data.firstIndex(of: UInt8(ascii: "\n")) {
            return data.index(after: newlineIndex)
        }
        return nil
    }

    /// 解析消息
    private func parseMessage(_ messageString: String) {
        // 移除空白字符
        let trimmedMessage = messageString.trimmingCharacters(in: .whitespacesAndNewlines)

        // 跳过空消息
        guard !trimmedMessage.isEmpty else { return }

        // 解析 JSON
        guard let agentState = parseAgentState(from: trimmedMessage) else {
            print("⚠️ 无法解析消息: \(trimmedMessage)")
            return
        }

        print("📨 收到代理状态: \(agentState.id) - \(agentState.status.displayName)")

        // 通知回调
        DispatchQueue.main.async {
            self.messageCallback?(agentState)
        }
    }

    /// 解析 AgentState
    private func parseAgentState(from jsonString: String) -> AgentState? {
        // 尝试解析为 JSON
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        do {
            // 首先尝试解析为标准 AgentState
            let decoder = JSONDecoder()
            let agentState = try decoder.decode(AgentState.self, from: data)
            return agentState
        } catch {
            // 尝试解析为 Claude Code 格式
            if let claudeFormat = parseClaudeCodeFormat(jsonString) {
                return claudeFormat
            }

            print("❌ 解析 JSON 失败: \(error)")
            return nil
        }
    }

    /// 解析 Claude Code 格式的消息
    /// - Parameter jsonString: JSON 字符串
    /// - Returns: AgentState 实例
    private func parseClaudeCodeFormat(_ jsonString: String) -> AgentState? {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        struct ClaudeCodeMessage: Decodable {
            let agent_id: String
            let status: String
            let terminal: String
            let timestamp: String?
        }

        do {
            let decoder = JSONDecoder()
            let message = try decoder.decode(ClaudeCodeMessage.self, from: data)

            // 解析 terminal 字段格式 "bundle_id:tab_id"
            let components = message.terminal.split(separator: ":")
            let bundleId = String(components.first ?? "")
            let tabId = components.count > 1 ? String(components[1]) : nil

            // 解析状态
            guard let agentStatus = AgentStatus.from(string: message.status) else {
                print("⚠️ 未知的状态类型: \(message.status)")
                return nil
            }

            return AgentState(
                id: message.agent_id,
                status: agentStatus,
                terminalAppBundleId: bundleId,
                terminalTabId: tabId,
                lastUpdated: message.timestamp ?? ISO8601DateFormatter().string(from: Date())
            )
        } catch {
            return nil
        }
    }

    // MARK: - 心跳机制

    /// 启动心跳
    private func startHeartbeat() {
        cancelHeartbeat()

        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: SocketMonitor.heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }

        print("💓 心跳已启动（每 \(SocketMonitor.heartbeatInterval) 秒）")
    }

    /// 取消心跳
    private func cancelHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    /// 发送心跳消息
    private func sendHeartbeat() {
        guard connectionStatus.isConnected else {
            return
        }

        let heartbeatMessage = "ping\n"
        guard let data = heartbeatMessage.data(using: .utf8) else {
            return
        }

        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ 发送心跳失败: \(error.localizedDescription)")
            }
        })
    }

    // MARK: - 重连机制

    /// 安排重连
    private func scheduleReconnect() {
        cancelReconnect()

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: currentReconnectDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("🔄 尝试重连...")
            self.connect()

            // 指数退避
            self.currentReconnectDelay = min(
                self.currentReconnectDelay * 2,
                SocketMonitor.maxReconnectDelay
            )
        }

        print("⏰ 将在 \(currentReconnectDelay) 秒后重连")
    }

    /// 取消重连
    private func cancelReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    // MARK: - 消息回调

    /// 设置消息回调
    /// - Parameter callback: 消息回调函数
    func setMessageCallback(_ callback: @escaping MessageCallback) {
        messageCallback = callback
    }

    // MARK: - 错误类型

    enum SocketError: LocalizedError {
        case invalidPort

        var errorDescription: String? {
            switch self {
            case .invalidPort:
                return "无效的端口号"
            }
        }
    }
}