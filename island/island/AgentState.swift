//
//  AgentState.swift
//  VibeIsland
//
//  代理状态数据模型
//

import Foundation

/// 代理状态枚举
enum AgentStatus: String, Codable, CaseIterable {
    case inProgress
    case complete
    case awaitingApproval

    /// 获取状态的显示文本
    var displayName: String {
        switch self {
        case .inProgress:
            return "进行中"
        case .complete:
            return "已完成"
        case .awaitingApproval:
            return "等待审批"
        }
    }

    /// 从字符串解析状态
    static func from(string value: String) -> AgentStatus? {
        switch value.lowercased() {
        case "in_progress":
            return .inProgress
        case "complete":
            return .complete
        case "awaiting_approval":
            return .awaitingApproval
        default:
            return nil
        }
    }
}

/// 代理状态数据模型
struct AgentState: Codable, Identifiable, Equatable {
    /// 代理唯一标识符
    let id: String

    /// 代理状态
    let status: AgentStatus

    /// 终端应用的 Bundle ID
    let terminalAppBundleId: String

    /// 终端标签页 ID（可选）
    let terminalTabId: String?

    /// 最后更新时间（ISO8601 格式）
    let lastUpdated: String

    /// Identifiable 协议要求
    var identifier: String {
        id
    }

    /// 创建新的代理状态
    init(
        id: String,
        status: AgentStatus,
        terminalAppBundleId: String,
        terminalTabId: String? = nil,
        lastUpdated: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.status = status
        self.terminalAppBundleId = terminalAppBundleId
        self.terminalTabId = terminalTabId
        self.lastUpdated = lastUpdated
    }

    /// 从 JSON 字符串创建 AgentState
    /// - Parameter jsonString: JSON 字符串
    /// - Returns: 解析成功的 AgentState 实例，失败返回 nil
    static func from(jsonString: String) -> AgentState? {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AgentState.self, from: data)
        } catch {
            print("解析 AgentState 失败: \(error)")
            return nil
        }
    }

    /// 转换为 JSON 字符串
    /// - Returns: JSON 字符串，转换失败返回 nil
    func toJSON() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("序列化 AgentState 失败: \(error)")
            return nil
        }
    }

    /// 创建副本并更新指定字段
    func with(
        status: AgentStatus? = nil,
        lastUpdated: String? = nil
    ) -> AgentState {
        AgentState(
            id: id,
            status: status ?? self.status,
            terminalAppBundleId: terminalAppBundleId,
            terminalTabId: terminalTabId,
            lastUpdated: lastUpdated ?? self.lastUpdated
        )
    }
}