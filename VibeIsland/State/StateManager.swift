//
//  StateManager.swift
//  VibeIsland
//
//  中央状态管理和持久化
//

import Foundation
import Combine

/// 状态管理器
/// 负责管理多个代理状态并提供持久化
class StateManager: ObservableObject {

    // MARK: - 单例

    /// 共享实例
    static let shared = StateManager()

    // MARK: - 发布的属性

    /// 所有代理状态
    @Published var agentStates: [AgentState] = []

    /// 代理 ID 到状态的映射
    private var stateDictionary: [String: AgentState] = [:]

    /// 代理顺序
    private var agentOrder: [String] = []

    /// 追踪每个代理的上一个状态（用于状态变化检测）
    private var lastAgentStates: [String: AgentStatus] = [:]

    // MARK: - 初始化

    private init() {
        loadPersistedStates()
    }

    // MARK: - 状态更新

    /// 更新或添加代理状态
    /// - Parameter agent: 代理状态
    func updateAgentState(_ agent: AgentState) {
        // 获取旧状态
        let oldStatus = stateDictionary[agent.id]?.status

        // 检查是否为新代理
        let isNewAgent = !stateDictionary.keys.contains(agent.id)

        // 检查状态是否实际变化
        let statusChanged = oldStatus != agent.status

        // 更新内部状态
        stateDictionary[agent.id] = agent

        // 更新代理顺序
        if isNewAgent {
            agentOrder.append(agent.id)
        }

        // 持久化到共享容器
        persistStates()

        // 更新发布的属性
        updatePublishedStates()

        // 更新状态历史
        lastAgentStates[agent.id] = agent.status

        // 仅在状态变化时发布通知
        if statusChanged || isNewAgent {
            NotificationCenter.default.post(
                name: .agentStateDidChange,
                object: nil,
                userInfo: [
                    "agentId": agent.id,
                    "oldStatus": oldStatus?.rawValue as Any,
                    "newStatus": agent.status.rawValue,
                    "isNewAgent": isNewAgent
                ]
            )
        }
    }

    /// 批量更新代理状态
    /// - Parameter agents: 代理状态数组
    func updateAgentStates(_ agents: [AgentState]) {
        var hasChanges = false

        for agent in agents {
            let oldStatus = stateDictionary[agent.id]?.status
            let isNewAgent = !stateDictionary.keys.contains(agent.id)
            let statusChanged = oldStatus != agent.status

            stateDictionary[agent.id] = agent

            if isNewAgent {
                agentOrder.append(agent.id)
            }

            if statusChanged || isNewAgent {
                hasChanges = true
            }

            lastAgentStates[agent.id] = agent.status
        }

        persistStates()
        updatePublishedStates()

        NotificationCenter.default.post(
            name: .agentStatesDidChange,
            object: nil,
            userInfo: ["count": agents.count, "hasChanges": hasChanges]
        )
    }

    // MARK: - 状态查询

    /// 获取所有代理状态
    /// - Returns: 代理状态数组（按添加顺序）
    func getAgentStates() -> [AgentState] {
        return agentOrder.compactMap { stateDictionary[$0] }
    }

    /// 获取指定 ID 的代理状态
    /// - Parameter id: 代理 ID
    /// - Returns: 代理状态，不存在返回 nil
    func getAgentState(id: String) -> AgentState? {
        return stateDictionary[id]
    }

    /// 获取指定状态的代理数量
    /// - Parameter status: 代理状态
    /// - Returns: 代理数量
    func getAgentCount(for status: AgentStatus) -> Int {
        return stateDictionary.values.filter { $0.status == status }.count
    }

    /// 检查是否有等待审批的代理
    /// - Returns: 是否有等待审批的代理
    func hasAwaitingApprovalAgents() -> Bool {
        return stateDictionary.values.contains { $0.status == .awaitingApproval }
    }

    // MARK: - 状态变化检测

    /// 检查代理状态是否发生变化
    /// - Parameters:
    ///   - agentId: 代理 ID
    ///   - newStatus: 新状态
    /// - Returns: 状态是否变化
    func didAgentStatusChange(_ agentId: String, newStatus: AgentStatus) -> Bool {
        let oldStatus = lastAgentStates[agentId]
        return oldStatus != newStatus
    }

    /// 获取代理的上一个状态
    /// - Parameter agentId: 代理 ID
    /// - Returns: 上一个状态，不存在返回 nil
    func getLastAgentStatus(_ agentId: String) -> AgentStatus? {
        return lastAgentStates[agentId]
    }

    // MARK: - 状态移除

    /// 移除指定 ID 的代理状态
    /// - Parameter id: 代理 ID
    func removeAgentState(id: String) {
        stateDictionary.removeValue(forKey: id)
        agentOrder.removeAll { $0 == id }
        lastAgentStates.removeValue(forKey: id)

        persistStates()
        updatePublishedStates()

        NotificationCenter.default.post(
            name: .agentStateDidRemove,
            object: nil,
            userInfo: ["agentId": id]
        )
    }

    /// 移除所有代理状态
    func removeAllAgentStates() {
        stateDictionary.removeAll()
        agentOrder.removeAll()
        lastAgentStates.removeAll()

        persistStates()
        updatePublishedStates()

        NotificationCenter.default.post(name: .agentStatesDidClear, object: nil)
    }

    // MARK: - 持久化

    /// 从共享容器加载持久化状态
    func loadPersistedStates() {
        // 加载代理状态
        stateDictionary = SharedContainer.loadAgentStates()

        // 加载代理顺序
        agentOrder = SharedContainer.loadAgentOrder()

        // 清理无效的顺序
        agentOrder = agentOrder.filter { stateDictionary[$0] != nil }

        // 初始化状态历史
        for (agentId, agentState) in stateDictionary {
            lastAgentStates[agentId] = agentState.status
        }

        // 更新发布的属性
        updatePublishedStates()

        print("✅ 加载了 \(stateDictionary.count) 个代理状态")
    }

    /// 持久化状态到共享容器
    private func persistStates() {
        SharedContainer.saveAgentStates(stateDictionary)
        SharedContainer.saveAgentOrder(agentOrder)
    }

    /// 更新发布的属性
    private func updatePublishedStates() {
        agentStates = getAgentStates()
    }
}

// MARK: - 通知名称

extension Notification.Name {
    /// 代理状态变化通知
    static let agentStateDidChange = Notification.Name("agentStateDidChange")

    /// 代理状态批量变化通知
    static let agentStatesDidChange = Notification.Name("agentStatesDidChange")

    /// 代理状态移除通知
    static let agentStateDidRemove = Notification.Name("agentStateDidRemove")

    /// 代理状态清空通知
    static let agentStatesDidClear = Notification.Name("agentStatesDidClear")
}