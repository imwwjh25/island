//
//  CompactStatusView.swift
//  VibeIsland
//
//  菜单栏紧凑状态视图
//

import SwiftUI
import Combine

/// 菜单栏紧凑状态视图
/// 显示代理状态指示器和数量徽章
struct CompactStatusView: View {
    // MARK: - 属性

    /// 状态管理器 - 从环境接收，不重新初始化
    @EnvironmentObject var stateManager: StateManager

    /// 菜单栏管理器 - 从环境接收，不重新初始化
    @EnvironmentObject var menuBarManager: MenuBarManager

    /// 是否有新的重要状态（用于视觉提示）
    @State private var hasNewImportantState = false

    /// 是否正在闪烁
    @State private var isBlinking = false

    /// 减少动画设置
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            // 状态指示圆点
            statusIndicators

            // 代理数量徽章
            if !stateManager.agentStates.isEmpty {
                agentCountBadge
            } else {
                // 调试：显示检测状态
                Text("○")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("点击查看详情")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            setupNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showVisualPrompt)) { notification in
            showVisualPrompt(notification: notification)
        }
        .animation(
            reducedMotion ? .none : Animation.easeInOut(duration: 0.5).repeatCount(3),
            value: isBlinking
        )
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
                .scaleEffect(hasNewImportantState ? 1.2 : 1.0)
                .shadow(color: hasNewImportantState ? accentColor : .clear, radius: hasNewImportantState ? 5 : 0)
            }
        }
    }

    /// 状态圆点
    /// - Parameter color: 圆点颜色
    /// - Returns: 状态圆点视图
    private func statusCircle(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: hasNewImportantState ? 12 : 10, height: hasNewImportantState ? 12 : 10)
    }

    // MARK: - 代理数量徽章

    /// 代理数量徽章
    private var agentCountBadge: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(stateManager.agentStates.count)")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // "待查看"徽章
            if hasNewImportantState {
                Text("!")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 14, height: 14)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }

    // MARK: - 辅助方法

    /// 获取强调色
    private var accentColor: Color {
        if stateManager.hasAwaitingApprovalAgents() {
            return .orange
        }
        if stateManager.getAgentCount(for: .complete) > 0 {
            return .green
        }
        return .blue
    }

    /// 获取辅助功能标签
    private var accessibilityLabel: String {
        let count = stateManager.agentStates.count
        var label = "Vibe Island 动态岛"

        if count > 0 {
            label += "，\(count) 个代理活跃"

            // 添加状态摘要
            let awaitingCount = stateManager.getAgentCount(for: .awaitingApproval)
            let inProgressCount = stateManager.getAgentCount(for: .inProgress)
            let completeCount = stateManager.getAgentCount(for: .complete)

            var statusSummary: [String] = []

            if awaitingCount > 0 {
                statusSummary.append("\(awaitingCount) 个等待审批")
            }
            if inProgressCount > 0 {
                statusSummary.append("\(inProgressCount) 个进行中")
            }
            if completeCount > 0 {
                statusSummary.append("\(completeCount) 个已完成")
            }

            if !statusSummary.isEmpty {
                label += "，" + statusSummary.joined(separator: "，")
            }
        } else {
            label += "，无活跃代理"
        }

        return label
    }

    // MARK: - 通知处理

    /// 设置通知监听
    private func setupNotifications() {
        // 通知监听已在 onReceive 中处理
    }

    /// 显示视觉提示
    /// - Parameter notification: 通知对象
    private func showVisualPrompt(notification: Notification) {
        guard reducedMotion == false else { return }

        hasNewImportantState = true
        isBlinking = true

        // 3 秒后重置
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            hasNewImportantState = false
            isBlinking = false
        }
    }
}

#Preview {
    CompactStatusView()
        .previewLayout(.sizeThatFits)
        .padding()
}