//
//  VibeIslandMenuBar.swift
//  VibeIsland
//
//  菜单栏管理器和 MenuBarExtra 入口点
//

import SwiftUI
import Combine

/// 菜单栏管理器
/// 负责控制 popover 展开状态和响应状态变化
class MenuBarManager: ObservableObject {
    /// 单例实例
    static let shared = MenuBarManager()

    /// 是否展开 popover
    @Published var isPopoverExpanded = false

    /// 订阅集合
    private var cancellables = Set<AnyCancellable>()

    /// 状态管理器
    private let stateManager = StateManager.shared

    /// 音效管理器
    private let soundManager = SoundManager.shared

    /// 进程监控器
    private let processMonitor = ProcessMonitor.shared

    private init() {
        setupNotifications()
        startMonitors()
    }

    // MARK: - 监控器启动

    /// 启动监控器
    private func startMonitors() {
        processMonitor.start()
        print("✅ 进程监控已启动")
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
            .sink { [weak self] _ in
                // 状态变化时更新 UI（通过 @Published 属性自动刷新）
                self?.objectWillChange.send()
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
            // 发布视觉提示通知
            NotificationCenter.default.post(
                name: .showVisualPrompt,
                object: nil,
                userInfo: ["status": newStatusString, "agentId": agentId]
            )

            print("🚀 显示视觉提示（代理：\(agentId)，状态：\(newStatus.displayName)）")
        }

        // 播放音效
        soundManager.playStateChangeSound()

        // 状态变化时触发 UI 更新
        objectWillChange.send()
    }

    /// 判断是否应该显示视觉提示
    private func shouldShowVisualPrompt(newStatus: AgentStatus, oldStatus: AgentStatus?) -> Bool {
        // 检查是否为新代理（新代理不显示视觉提示，避免干扰）
        guard oldStatus != nil else { return false }

        // 检查是否为需要视觉提示的状态
        return newStatus == .awaitingApproval || newStatus == .complete
    }
}

/// Vibe Island 菜单栏应用
@main
struct VibeIslandMenuBar: App {
    // MARK: - 属性

    /// 状态管理器 - 使用 @StateObject 确保单例在视图生命周期中持久存在
    @StateObject private var stateManager = StateManager.shared

    /// 菜单栏管理器 - 使用 @StateObject 确保单例在视图生命周期中持久存在
    @StateObject private var menuBarManager = MenuBarManager.shared

    // MARK: - Body

    var body: some Scene {
        MenuBarExtra("Vibe Island", systemImage: "sparkles") {
            ExpandedDetailsView()
                .environmentObject(stateManager)
                .environmentObject(menuBarManager)
        }
        .menuBarExtraStyle(.window)
    }
}