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

        // 等待审批的代理（最高优先级）- 品红色
        if counts.awaitingApproval > 0 {
            statusDot(color: Color(red: 1.0, green: 0.0, blue: 1.0), statusName: "等待审批", count: counts.awaitingApproval, isBlinking: isBlinking)
        }

        // 进行中的代理 - 青色
        if counts.inProgress > 0 {
            statusDot(color: Color(red: 0.0, green: 1.0, blue: 1.0), statusName: "进行中", count: counts.inProgress, isBlinking: false)
        }

        // 已完成的代理 - 黄色
        if counts.complete > 0 {
            statusDot(color: Color(red: 1.0, green: 1.0, blue: 0.0), statusName: "已完成", count: counts.complete, isBlinking: false)
        }

        // 空闲状态（无代理）- 灰色
        if counts.total == 0 {
            statusDot(color: .gray, statusName: "空闲", count: 0, isBlinking: false)
        }
    }

    /// 状态圆点
    @ViewBuilder
    private func statusDot(color: Color, statusName: String, count: Int, isBlinking: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: isBlinking ? 10 : 8, height: isBlinking ? 10 : 8)
            .opacity(isBlinking ? 0.5 : 1.0)
            .shadow(color: isBlinking ? color.opacity(0.6) : .clear, radius: isBlinking ? 4 : 0)
            .animation(
                isBlinking && !reducedMotion
                    ? Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)
                    : .easeInOut(duration: 0.25),
                value: isBlinking
            )
            .overlay(
                Group {
                    if count > 1 {
                        Text("\(count)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            )
            .accessibilityLabel("\(statusName)\(count > 1 ? ", \(count) 个" : "")")
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

        // 获取状态信息
        let statusString = notification.userInfo?["status"] as? String
        let status = AgentStatus(rawValue: statusString ?? "")

        // 根据状态调整闪烁时长
        let blinkDuration: TimeInterval
        switch status {
        case .awaitingApproval:
            blinkDuration = 5.0 // 等待审批需要更长提醒
        case .complete:
            blinkDuration = 2.0 // 完成短暂提醒
        default:
            blinkDuration = 3.0
        }

        hasNewImportantState = true
        isBlinking = true

        // 重置闪烁
        DispatchQueue.main.asyncAfter(deadline: .now() + blinkDuration) {
            hasNewImportantState = false
            isBlinking = false
        }
    }
}

#Preview {
    CompactStatusView()
        .padding()
}