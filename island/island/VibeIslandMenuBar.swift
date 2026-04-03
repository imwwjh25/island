//
//  VibeIslandMenuBar.swift
//  VibeIsland
//
//  菜单栏管理器和 MenuBarExtra 入口点
//

import SwiftUI
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

/// 菜单栏管理器
/// 负责控制 popover 展开状态和响应状态变化
class MenuBarManager: ObservableObject {
    /// 单例实例
    static let shared = MenuBarManager()

    /// 是否展开 popover
    @Published var isPopoverExpanded = false

    /// 订阅集合
    private var cancellables = Set<AnyCancellable>()

    /// 上次 widget 重新加载时间
    private var lastWidgetReloadTime: Date?

    /// widget 重新加载间隔（秒）
    private let widgetReloadInterval: TimeInterval = 1.0

    /// 状态管理器
    private let stateManager = StateManager.shared

    /// 音效管理器
    private let soundManager = SoundManager.shared

    /// 套接字监控器
    private var socketMonitor: SocketMonitor?

    /// 窗口监控器
    private var windowMonitor: WindowMonitor?

    private init() {
        setupNotifications()
        setupSocketMonitor()
        setupWindowMonitor()
    }

    // MARK: - Socket 监控设置

    /// 设置套接字监控器
    private func setupSocketMonitor() {
        socketMonitor = SocketMonitor()

        // 配置消息回调
        socketMonitor?.setMessageCallback { [weak stateManager] agentState in
            stateManager?.updateAgentState(agentState)
            print("✅ 已更新代理状态: \(agentState.id) - \(agentState.status.displayName)")
        }

        // 启动监控
        socketMonitor?.start()
    }

    // MARK: - 窗口监控设置

    /// 设置窗口监控器
    private func setupWindowMonitor() {
        windowMonitor = WindowMonitor.shared
        windowMonitor?.start()
        print("✅ 窗口监控已启动")
    }

    // MARK: - 通知设置

    /// 设置通知监听
    private func setupNotifications() {
        // 监听单个代理状态变化
        NotificationCenter.default.publisher(for: .agentStateDidChange)
            .sink { [weak self] notification in
                self?.handleStateChange(notification: notification)
            }
            .store(in: &cancellables)

        // 监听批量状态变化
        NotificationCenter.default.publisher(for: .agentStatesDidChange)
            .sink { [weak self] notification in
                self?.handleBatchStateChange(notification: notification)
            }
            .store(in: &cancellables)
    }

    // MARK: - 状态变化处理

    /// 处理状态变化通知
    func handleStateChange(notification: Notification) {
        guard let agentId = notification.userInfo?["agentId"] as? String,
              let newStatusString = notification.userInfo?["newStatus"] as? String,
              let newStatus = AgentStatus(rawValue: newStatusString),
              let oldStatusString = notification.userInfo?["oldStatus"] as? String,
              let oldStatus = AgentStatus(rawValue: oldStatusString) else {
            return
        }

        // 检查是否为需要视觉提示的状态
        if shouldShowVisualPrompt(newStatus: newStatus, oldStatus: oldStatus) {
            NotificationCenter.default.post(
                name: .showVisualPrompt,
                object: nil,
                userInfo: ["status": newStatusString, "agentId": agentId]
            )
            print("🚀 显示视觉提示（代理：\(agentId)，状态：\(newStatus.displayName)）")
        }

        // 播放音效
        soundManager.playStateChangeSound()

        // 触发 widget 更新
        triggerWidgetUpdate(agentId: agentId)

        // 状态变化时触发 UI 更新
        objectWillChange.send()
    }

    /// 处理批量状态变化
    func handleBatchStateChange(notification: Notification) {
        guard let hasChanges = notification.userInfo?["hasChanges"] as? Bool, hasChanges else {
            return
        }

        soundManager.playStateChangeSound()
        triggerWidgetUpdate()
        objectWillChange.send()
    }

    /// 判断是否应该显示视觉提示
    private func shouldShowVisualPrompt(newStatus: AgentStatus, oldStatus: AgentStatus?) -> Bool {
        guard oldStatus != nil else { return false }
        return newStatus == .awaitingApproval || newStatus == .complete
    }

    // MARK: - Widget 更新

    /// 触发 widget 时间线更新（带频率限制）
    func triggerWidgetUpdate(agentId: String? = nil) {
        if let lastTime = lastWidgetReloadTime {
            let timeSinceLastReload = Date().timeIntervalSince(lastTime)
            if timeSinceLastReload < widgetReloadInterval {
                print("⏳ 跳过 widget 重新加载（频率限制）")
                return
            }
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        lastWidgetReloadTime = Date()

        if let agentId = agentId {
            print("🔄 已触发 widget 时间线更新（代理：\(agentId)）")
        } else {
            print("🔄 已触发 widget 时间线更新（批量）")
        }
        #else
        print("⚠️ WidgetKit 不可用，跳过 widget 更新")
        #endif
    }
}

/// Vibe Island 菜单栏应用
@main
struct VibeIslandMenuBar: App {
    /// 菜单栏管理器
    @ObservedObject private var menuBarManager = MenuBarManager.shared

    var body: some Scene {
        MenuBarExtra("Vibe Island", systemImage: "sparkles") {
            ExpandedDetailsView()
        }
        .menuBarExtraStyle(.window)
    }
}