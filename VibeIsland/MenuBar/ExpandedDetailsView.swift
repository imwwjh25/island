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

    /// 状态管理器 - 从环境接收，不重新初始化
    @EnvironmentObject var stateManager: StateManager

    /// 菜单栏管理器 - 从环境接收，不重新初始化
    @EnvironmentObject var menuBarManager: MenuBarManager

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

    // MARK: - 状态变量

    /// 是否显示错误警告
    @State private var showAlert = false

    /// 错误消息
    @State private var errorMessage = ""

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
        .alert("跳转失败", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 环境变量

    /// 减少动画设置
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    // MARK: - 标题栏

    /// 跳转到终端标签页
    /// - Parameter agent: 代理状态
    private func jumpToTerminalTab(for agent: AgentState) {
        // 检查是否有终端应用信息
        guard !agent.terminalAppBundleId.isEmpty else {
            errorMessage = "代理没有关联的终端应用"
            showAlert = true
            return
        }

        // 检查是否有标签页 ID
        guard let tabId = agent.terminalTabId else {
            errorMessage = "代理没有关联的标签页 ID"
            showAlert = true
            return
        }

        // 根据 Bundle ID 识别终端类型
        let terminalType: TerminalType
        switch agent.terminalAppBundleId {
        case "com.googlecode.iterm2":
            terminalType = .iterm2
        case "com.apple.terminal":
            terminalType = .terminal
        default:
            errorMessage = "不支持的终端应用：\(agent.terminalAppBundleId)"
            showAlert = true
            return
        }

        // 检查终端应用是否运行
        guard TerminalController.shared.isTerminalRunning(terminalType) else {
            errorMessage = "\(terminalType.displayName) 未运行，请先启动该应用"
            showAlert = true
            return
        }

        // 执行跳转
        let success = TerminalController.shared.jumpToTab(terminal: terminalType, tabId: tabId)

        if !success {
            errorMessage = "无法跳转到标签页 \(tabId)，请检查标签页是否存在"
            showAlert = true
        }
    }

    /// 标题栏
    private var header: some View {
        HStack {
            Text("Vibe Island")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: {
                // 关闭 popover（通过点击外部区域）
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("关闭")
            .accessibilityLabel("关闭")
            .accessibilityHint("关闭详细视图")
            .accessibilityAddTraits(.isButton)
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
        .accessibilityLabel("代理列表")
        .accessibilityHint("垂直滚动查看所有代理")
        .animation(reducedMotion ? .none : .easeInOut(duration: 0.3), value: stateManager.agentStates.count)
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
        .onTapGesture {
            jumpToTerminalTab(for: agent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("代理 \(agent.id)，状态 \(agent.status.displayName)")
        .accessibilityHint("点击跳转到标签页 \(agent.terminalTabId ?? "无")")
        .accessibilityAddTraits(.isButton)
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
            .accessibilityHidden(true)
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

            // 调试信息
            VStack(spacing: 4) {
                Text("进程监控运行中...")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("每 3 秒自动检测 Claude Code 进程")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Button("手动检测") {
                    ProcessMonitor.shared.manualCheck()
                    // 延迟刷新 UI
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // 触发 UI 刷新
                    }
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)

                // 显示当前检测到的数量
                Text("已检测: \(stateManager.agentStates.count) 个会话")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 32)
        .accessibilityLabel("无活跃代理")
        .accessibilityHint("当前没有运行中的 Claude Code 代理")
    }

    // MARK: - 页脚

    /// 页脚
    private var footer: some View {
        Text("共 \(stateManager.agentStates.count) 个代理")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .accessibilityLabel("共 \(stateManager.agentStates.count) 个代理")
            .accessibilityAddTraits(.isStaticText)
            .accessibilityHidden(stateManager.agentStates.isEmpty)
    }
}

#Preview {
    ExpandedDetailsView()
        .previewLayout(.fixed(width: 400, height: 500))
        .padding()
}