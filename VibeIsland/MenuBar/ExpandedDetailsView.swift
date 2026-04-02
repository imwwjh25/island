//
//  ExpandedDetailsView.swift
//  VibeIsland
//
//  展开详细视图（Popover 内容）
//

import SwiftUI

/// 展开详细视图
/// 显示所有代理的详细信息
struct ExpandedDetailsView: View {
    // MARK: - 属性

    /// 状态管理器
    @ObservedObject private var stateManager = StateManager.shared

    /// 菜单栏管理器
    @ObservedObject private var menuBarManager = MenuBarManager.shared

    /// Popover 最小宽度
    private let minWidth: CGFloat = 280

    /// Popover 理想宽度
    private let idealWidth: CGFloat = 320

    /// Popover 最大宽度
    private let maxWidth: CGFloat = 400

    /// Popover 最小高度
    private let minHeight: CGFloat = 200

    /// Popover 理想高度
    private let idealHeight: CGFloat = 300

    /// Popover 最大高度
    private let maxHeight: CGFloat = 500

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            header

            Divider()

            // 代理列表
            if stateManager.agentStates.isEmpty {
                emptyStateView
            } else {
                agentList
                footer
            }
        }
        .frame(
            minWidth: minWidth,
            idealWidth: idealWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            idealHeight: idealHeight,
            maxHeight: maxHeight
        )
        .padding()
    }

    // MARK: - 标题栏

    /// 标题栏
    private var header: some View {
        HStack {
            Text("Vibe Island")
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                // 关闭 popover（通过点击外部区域）
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("关闭")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 代理列表

    /// 代理列表
    private var agentList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(stateManager.agentStates) { agent in
                    agentCard(for: agent)

                    if agent.id != stateManager.agentStates.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    /// 代理卡片
    /// - Parameter agent: 代理状态
    /// - Returns: 代理卡片视图
    private func agentCard(for agent: AgentState) -> some View {
        HStack(spacing: 12) {
            // 状态指示圆点
            statusCircle(for: agent.status)

            // 代理信息
            VStack(alignment: .leading, spacing: 2) {
                Text("代理 \(agent.id)")
                    .font(.body)
                    .foregroundColor(.primary)

                if let tabId = agent.terminalTabId {
                    Text("标签页 \(tabId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 状态标签
            statusLabel(for: agent.status)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    /// 状态圆点
    /// - Parameter status: 代理状态
    /// - Returns: 状态圆点视图
    private func statusCircle(for status: AgentStatus) -> some View {
        Circle()
            .fill(statusColor(for: status))
            .frame(width: 10, height: 10)
    }

    /// 状态颜色
    /// - Parameter status: 代理状态
    /// - Returns: 状态颜色
    private func statusColor(for status: AgentStatus) -> Color {
        switch status {
        case .inProgress:
            return .blue
        case .complete:
            return .green
        case .awaitingApproval:
            return .orange
        }
    }

    /// 状态标签
    /// - Parameter status: 代理状态
    /// - Returns: 状态标签视图
    private func statusLabel(for status: AgentStatus) -> some View {
        Text(status.displayName)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(for: status))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - 空状态视图

    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("无活跃代理")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - 页脚

    /// 页脚
    private var footer: some View {
        Text("共 \(stateManager.agentStates.count) 个代理")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
    }
}

#Preview {
    ExpandedDetailsView()
        .previewLayout(.fixed(width: 400, height: 500))
        .padding()
}