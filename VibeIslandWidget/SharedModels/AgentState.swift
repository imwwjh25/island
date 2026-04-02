//
//  AgentState.swift
//  VibeIslandWidget
//
//  代理状态数据模型（Widget 扩展共享）
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
}
