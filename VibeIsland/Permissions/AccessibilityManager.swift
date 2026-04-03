//
//  AccessibilityManager.swift
//  VibeIsland
//
//  Accessibility 权限管理
//

import ApplicationServices
import Combine
import Cocoa

/// Accessibility 权限管理器
/// 负责检查、请求和监控 Accessibility 权限状态
class AccessibilityManager: ObservableObject {

    // MARK: - 单例

    static let shared = AccessibilityManager()

    // MARK: - 发布属性

    /// 是否已授权
    @Published var hasPermission: Bool = false

    /// 是否已提示过用户
    @Published var hasPromptedUser: Bool = false

    // MARK: - 私有属性

    private var cancellables = Set<AnyCancellable>()

    // MARK: - 初始化

    private init() {
        checkPermission(promptUser: false)
        startMonitoring()
    }

    // MARK: - 权限检查

    /// 检查权限状态
    /// - Parameter promptUser: 是否显示系统授权对话框
    func checkPermission(promptUser: Bool) {
        let options: CFDictionary?
        if promptUser {
            options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        } else {
            options = nil
        }

        hasPermission = AXIsProcessTrustedWithOptions(options)

        if promptUser {
            hasPromptedUser = true
        }

        print("Accessibility 权限状态: \(hasPermission ? "已授权" : "未授权")")
    }

    // MARK: - 权限监控

    /// 启动权限变化监听
    func startMonitoring() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.hasPermission = AXIsProcessTrusted()
            print("权限变化通知: \(notification.name)")
        }
    }

    // MARK: - 系统设置

    /// 打开系统设置中的 Accessibility 页面
    func openAccessibilitySettings() {
        if #available(macOS 13.0, *) {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            NSWorkspace.shared.open(url!)
        } else {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security")
            NSWorkspace.shared.open(url!)
        }
    }
}