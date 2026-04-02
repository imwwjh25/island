//
//  CompactStatusView.swift
//  VibeIsland
//
//  菜单栏紧凑状态视图
//

import SwiftUI

/// 菜单栏紧凑状态视图
/// 显示代理状态指示器和数量徽章
struct CompactStatusView: View {
    // MARK: - 属性

    /// 状态管理器
    @ObservedObject private var stateManager = StateManager.shared

    /// 菜单栏管理器
    @ObservedObject private var menuBarManager = MenuBarManager.shared

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            // 状态指示圆点
            statusIndicators

            // 代理数量徽章
            if !stateManager.agentStates.isEmpty {
                agentCountBadge
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 状态指示圆点

    /// 状态指示圆点
    private var statusIndicators: some View {
        ZStack {
            // 背景图标
            if stateManager.agentStates.isEmpty {
                Image(systemName: "island")
                    .foregroundColor(.secondary)
            }

            // 状态圆点
            if !stateManager.agentStates.isEmpty {
                HStack(spacing: 4) {
                    // 等待审批状态圆点（优先级最高）
                    if stateManager.hasAwaitingApprovalAgents() {
                        statusCircle(color: .orange)
                    }

                    // 进行中状态圆点
                    if stateManager.getAgentCount(for: .inProgress) > 0 {
                        statusCircle(color: .blue)
                    }

                    // 完成状态圆点
                    if stateManager.getAgentCount(for: .complete) > 0 {
                        statusCircle(color: .green)
                    }
                }
            }
        }
    }

    /// 状态圆点
    /// - Parameter color: 圆点颜色
    /// - Returns: 状态圆点视图
    private func statusCircle(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }

    // MARK: - 代理数量徽章

    /// 代理数量徽章
    private var agentCountBadge: some View {
        Text("\(stateManager.agentStates.count)")
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    CompactStatusView()
        .previewLayout(.sizeThatFits)
        .padding()
}