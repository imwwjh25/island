//
//  VibeIslandApp.swift
//  VibeIsland
//
//  主应用入口点
//

import SwiftUI
import Combine

@main
struct VibeIslandApp: App {
    // MARK: - 属性

    /// 状态管理器
    private let stateManager = StateManager.shared

    /// 套接字监控器
    @StateObject private var socketMonitor = SocketMonitor()

    /// 音效管理器
    private let soundManager = SoundManager.shared

    /// 订阅集合
    private var cancellables = Set<AnyCancellable>()

    /// 上次widget重新加载时间
    private var lastWidgetReloadTime: Date?

    /// widget重新加载间隔（秒）
    private let widgetReloadInterval: TimeInterval = 1.0

    // MARK: - 初始化

    init() {
        setupIntegration()
    }

    // MARK: - Body

    var body: some Scene {
        // MenuExtra 应用（菜单栏应用）
        MenuExtra("Vibe Island") {
            MenuSection {
                Text("动态岛监控")
                    .foregroundColor(.secondary)
            }

            Divider()

            Button("偏好设置") {
                // TODO: 打开偏好设置窗口
            }

            Button("退出", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: "island")
        }
    }

    // MARK: - 集成设置

    /// 设置 SocketMonitor、StateManager 和 SoundManager 的集成
    private func setupIntegration() {
        // 配置 SocketMonitor 消息回调
        socketMonitor.setMessageCallback { [weak stateManager] agentState in
            // 收到消息后更新 StateManager
            stateManager?.updateAgentState(agentState)

            print("✅ 已更新代理状态: \(agentState.id) - \(agentState.status.displayName)")
        }

        // 监听状态变化通知
        setupStateChangeNotifications()

        // 启动套接字监控
        socketMonitor.start()
    }

    /// 设置状态变化通知监听
    private func setupStateChangeNotifications() {
        // 监听单个代理状态变化
        NotificationCenter.default.publisher(for: .agentStateDidChange)
            .sink { [weak self] notification in
                self?.handleAgentStateDidChange(notification)
            }
            .store(in: &cancellables)

        // 监听批量状态变化
        NotificationCenter.default.publisher(for: .agentStatesDidChange)
            .sink { [weak self] notification in
                self?.handleAgentStatesDidChange(notification)
            }
            .store(in: &cancellables)
    }

    /// 处理单个代理状态变化
    private func handleAgentStateDidChange(_ notification: Notification) {
        guard let agentId = notification.userInfo?["agentId"] as? String else {
            return
        }

        // 播放状态变化音效
        playStateChangeSound()

        // 触发 widget 更新
        triggerWidgetUpdate(agentId: agentId)
    }

    /// 处理批量状态变化
    private func handleAgentStatesDidChange(_ notification: Notification) {
        // 检查是否有实际变化
        guard let hasChanges = notification.userInfo?["hasChanges"] as? Bool, hasChanges else {
            return
        }

        // 批量更新时也播放音效
        playStateChangeSound()

        // 触发 widget 更新
        triggerWidgetUpdate()
    }

    // MARK: - 音效播放

    /// 播放状态变化音效
    private func playStateChangeSound() {
        soundManager.playStateChangeSound()
    }

    // MARK: - Widget 更新

    /// 触发 widget 时间线更新（带频率限制）
    /// - Parameter agentId: 代理 ID（可选）
    private func triggerWidgetUpdate(agentId: String? = nil) {
        // 检查频率限制
        if let lastTime = lastWidgetReloadTime {
            let timeSinceLastReload = Date().timeIntervalSince(lastTime)
            if timeSinceLastReload < widgetReloadInterval {
                print("⏳ 跳过 widget 重新加载（频率限制）：\(timeSinceLastReload)s < \(widgetReloadInterval)s")
                return
            }
        }

        #if canImport(WidgetKit)
        import WidgetKit

        // 重新加载所有 widget 时间线
        WidgetCenter.shared.reloadAllTimelines()

        lastWidgetReloadTime = Date()

        if let agentId = agentId {
            print("🔄 已触发 widget 时间线更新（代理：\(agentId)）")
        } else {
            print("🔄 已触发 widget 时间线更新（批量）")
        }
        #endif
    }
}