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

    /// 是否有新的重要状态（用于视觉提示）
    @State private var hasNewImportantState = false

    /// 是否正在闪烁
    @State private var isBlinking = false

    /// 减少动画设置
    @Environment(\.accessibilityReduceMotion) var reducedMotion

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("点击查看详情")
        .accessibilityAddTraits(.isButton)
        .onReceive(NotificationCenter.default.publisher(for: .showVisualPrompt)) { notification in
            showVisualPrompt(notification: notification)
        }
    }

    // MARK: - 子视图

    /// 状态指示器
    @ViewBuilder
    private var statusIndicators: some View {
        let counts = getStatusCounts()

        // 等待审批的代理（最高优先级）
        if counts.awaitingApproval > 0 {
            statusDot(color: .orange, count: counts.awaitingApproval, isBlinking: isBlinking)
        }

        // 进行中的代理
        if counts.inProgress > 0 {
            statusDot(color: .blue, count: counts.inProgress, isBlinking: false)
        }

        // 已完成的代理
        if counts.complete > 0 {
            statusDot(color: .green, count: counts.complete, isBlinking: false)
        }

        // 空闲状态（无代理）
        if counts.total == 0 {
            statusDot(color: .gray, count: 0, isBlinking: false)
        }
    }

    /// 状态圆点
    @ViewBuilder
    private func statusDot(color: Color, count: Int, isBlinking: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .opacity(isBlinking ? 0.3 : 1.0)
            .animation(isBlinking && !reducedMotion ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: isBlinking)
            .overlay(
                Group {
                    if count > 1 {
                        Text("\(count)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            )
            .accessibilityLabel("\(color == .orange ? "等待审批" : color == .blue ? "进行中" : color == .green ? "已完成" : "空闲")\(count > 1 ? ", \(count) 个" : "")")
    }

    /// 代理数量徽章
    @ViewBuilder
    private var agentCountBadge: some View {
        let counts = getStatusCounts()

        if counts.total > 0 {
            Text("\(counts.total)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.secondary))
        }
    }

    // MARK: - 辅助方法

    /// 获取各状态数量
    private func getStatusCounts() -> (total: Int, inProgress: Int, complete: Int, awaitingApproval: Int) {
        let states = stateManager.agentStates
        return (
            total: states.count,
            inProgress: states.filter { $0.status == .inProgress }.count,
            complete: states.filter { $0.status == .complete }.count,
            awaitingApproval: states.filter { $0.status == .awaitingApproval }.count
        )
    }

    /// 无障碍标签
    private var accessibilityLabel: String {
        let counts = getStatusCounts()
        if counts.total == 0 {
            return "Vibe Island: 无活跃代理"
        }

        var parts: [String] = []
        if counts.awaitingApproval > 0 {
            parts.append("\(counts.awaitingApproval) 个等待审批")
        }
        if counts.inProgress > 0 {
            parts.append("\(counts.inProgress) 个进行中")
        }
        if counts.complete > 0 {
            parts.append("\(counts.complete) 个已完成")
        }

        return "Vibe Island: " + parts.joined(separator: ", ")
    }

    /// 显示视觉提示
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
        .padding()
}