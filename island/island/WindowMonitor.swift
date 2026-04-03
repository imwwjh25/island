//
//  WindowMonitor.swift
//  VibeIsland
//
//  窗口监控器 - 主动检测活跃窗口中的 Agent 状态
//

import AppKit
import Foundation

/// 窗口监控器
/// 通过监听窗口激活事件来检测 Claude Code Agent 状态
class WindowMonitor {

    // MARK: - 属性

    /// 共享实例
    static let shared = WindowMonitor()

    /// 状态管理器引用
    private let stateManager = StateManager.shared

    /// 是否正在监控
    private var isMonitoring = false

    /// Claude Code Bundle ID
    private let claudeCodeBundleId = "com.anthropic.claudecode"

    /// Terminal Bundle IDs
    private let terminalBundleIds = [
        "com.googlecode.iterm2",
        "com.apple.terminal"
    ]

    /// 监控间隔（秒）
    private let monitorInterval: TimeInterval = 2.0

    /// 监控定时器
    private var monitorTimer: Timer?

    /// 上次检测到的窗口标题
    private var lastWindowTitle: String = ""

    // MARK: - 初始化

    private init() {}

    // MARK: - 监控控制

    /// 启动窗口监控
    func start() {
        if isMonitoring { return }

        isMonitoring = true
        print("🚀 窗口监控已启动")

        // 监听应用激活通知
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        // 启动定时轮询（作为备份机制）
        startPolling()
    }

    /// 停止窗口监控
    func stop() {
        if !isMonitoring { return }

        isMonitoring = false
        print("⏹ 窗口监控已停止")

        NSWorkspace.shared.notificationCenter.removeObserver(self)
        stopPolling()
    }

    // MARK: - 定时轮询

    /// 启动定时轮询
    private func startPolling() {
        monitorTimer = Timer.scheduledTimer(
            withTimeInterval: monitorInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkActiveWindow()
        }
    }

    /// 停止定时轮询
    private func stopPolling() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    // MARK: - 通知处理

    /// 应用激活通知处理
    @objc private func applicationActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }

        // 检查是否是相关应用
        let bundleId = app.bundleIdentifier ?? ""
        if isRelevantApplication(bundleId) {
            print("📱 应用激活: \(app.localizedName ?? bundleId)")
            checkActiveWindow()
        }
    }

    // MARK: - 窗口检测

    /// 检查当前活跃窗口
    func checkActiveWindow() {
        // 获取前端应用
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return
        }

        let bundleId = frontmostApp.bundleIdentifier ?? ""

        // 检查是否是终端应用（可能正在运行 Claude Code）
        if terminalBundleIds.contains(bundleId) {
            checkTerminalWindow(frontmostApp)
        }
    }

    /// 检查终端窗口中的 Claude Code 会话
    private func checkTerminalWindow(_ app: NSRunningApplication) {
        // 使用 Accessibility API 获取窗口标题
        let windowTitle = getWindowTitle(for: app)

        guard !windowTitle.isEmpty, windowTitle != lastWindowTitle else {
            return
        }

        lastWindowTitle = windowTitle
        print("🪟 窗口标题: \(windowTitle)")

        // 解析窗口标题，检测 Agent 状态
        parseWindowTitle(windowTitle, bundleId: app.bundleIdentifier ?? "")
    }

    /// 使用 Accessibility API 获取窗口标题
    private func getWindowTitle(for app: NSRunningApplication) -> String {
        let pid = app.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)

        // 获取焦点窗口
        var focusedWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appRef,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindow
        )

        guard result == .success, let window = focusedWindow else {
            return ""
        }

        // 获取窗口标题
        var title: AnyObject?
        let titleResult = AXUIElementCopyAttributeValue(
            window as! AXUIElement,
            kAXTitleAttribute as CFString,
            &title
        )

        guard titleResult == .success, let titleString = title as? String else {
            return ""
        }

        return titleString
    }

    // MARK: - 标题解析

    /// 解析窗口标题检测 Agent 状态
    private func parseWindowTitle(_ title: String, bundleId: String) {
        // 检测 Claude Code 相关标识
        // 常见格式：
        // - "Claude Code - session_xxx"
        // - "claude@xxx:~$"
        // - 包含 "agent" 关键字

        // 检测是否是 Claude Code 会话
        guard isClaudeCodeSession(title) else {
            return
        }

        // 生成唯一 Agent ID（基于窗口标题）
        let agentId = generateAgentId(from: title)

        // 检测状态
        let status = detectStatus(from: title)

        // 提取标签页信息
        let tabInfo = extractTabInfo(from: title)

        // 更新状态
        let agentState = AgentState(
            id: agentId,
            status: status,
            terminalAppBundleId: bundleId,
            terminalTabId: tabInfo,
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )

        stateManager.updateAgentState(agentState)
        print("✅ 检测到 Agent: \(agentId) - \(status.displayName)")
    }

    /// 检测是否是 Claude Code 会话
    private func isClaudeCodeSession(_ title: String) -> Bool {
        let lowercased = title.lowercased()

        // 检测关键词
        let keywords = [
            "claude code",
            "claude-code",
            "claude @",
            "claude>",
            "anthropic",
            "agent"
        ]

        for keyword in keywords {
            if lowercased.contains(keyword) {
                return true
            }
        }

        // 检测命令行特征
        if lowercased.contains("claude") && lowercased.contains("$") {
            return true
        }

        return false
    }

    /// 从标题生成 Agent ID
    private func generateAgentId(from title: String) -> String {
        // 尝试从标题提取会话 ID
        // 格式: "Claude Code - session_xxx" -> "session_xxx"

        let patterns = [
            "session[\\s_-]([a-zA-Z0-9]+)",
            "agent[\\s_-]([a-zA-Z0-9]+)",
            "claude[\\s_-]([a-zA-Z0-9]+)"
        ]

        for pattern in patterns {
            if let match = title.range(of: pattern, options: .regularExpression) {
                let id = String(title[match]).replacingOccurrences(of: "[\\s_-]", with: "-", options: .regularExpression)
                return "agent-" + id.lowercased()
            }
        }

        // 如果没有匹配，使用标题哈希
        return "agent-" + String(abs(title.hashValue))
    }

    /// 从标题检测状态
    /// 检测优先级: 错误 > 等待审批 > 完成 > 进行中
    private func detectStatus(from title: String) -> AgentStatus {
        let lowercased = title.lowercased()

        // 1. 检测错误状态（最高优先级）
        if lowercased.contains("error") ||
           lowercased.contains("failed") ||
           lowercased.contains("unable to") ||
           lowercased.contains("exception") ||
           lowercased.contains("fatal") {
            // 如果同时包含等待关键词，可能是在等待用户处理错误
            if lowercased.contains("awaiting") || lowercased.contains("waiting") {
                return .awaitingApproval
            }
            // 错误状态视为等待审批（需要用户介入）
            return .awaitingApproval
        }

        // 2. 检测等待审批状态（排除 "thinking..." 等误判）
        // 明确的等待审批关键词
        let awaitingKeywords = [
            "awaiting your approval",
            "awaiting approval",
            "waiting for approval",
            "waiting for input",
            "waiting for confirmation",
            "needs approval",
            "requires approval",
            "please confirm",
            "y/n",
            "yes/no",
            "approve?",
            "confirm?"
        ]

        for keyword in awaitingKeywords {
            if lowercased.contains(keyword) {
                return .awaitingApproval
            }
        }

        // 检测问号结尾的提示（但排除 "thinking?" 等内部状态）
        // 只在标题包含明确的交互提示词时才判定为等待审批
        if lowercased.contains("?") {
            let promptIndicators = ["?", "y/n", "yes/no", "choose", "select", "which", "would you"]
            for indicator in promptIndicators {
                if lowercased.contains(indicator) {
                    // 确保不是内部思考状态
                    if !lowercased.contains("thinking") && !lowercased.contains("processing") {
                        return .awaitingApproval
                    }
                }
            }
        }

        // 3. 检测完成状态
        let completeKeywords = [
            "complete!",
            "completed",
            "done!",
            "task complete",
            "task finished",
            "successfully",
            "success!",
            "finished",
            "all done"
        ]

        for keyword in completeKeywords {
            if lowercased.contains(keyword) {
                return .complete
            }
        }

        // 4. 默认为进行中
        return .inProgress
    }

    /// 从标题提取标签页信息
    private func extractTabInfo(from title: String) -> String? {
        // 尝试提取标签页标识
        // iTerm2 格式: "Session Name - iTerm2"
        // Terminal.app 格式: "Terminal — tabname"

        let separators = [" — ", " - ", " – "]
        for sep in separators {
            if let range = title.range(of: sep) {
                let before = String(title[title.startIndex..<range.lowerBound])
                if !before.isEmpty {
                    return before
                }
            }
        }

        return nil
    }

    // MARK: - 辅助方法

    /// 检查是否是相关应用
    private func isRelevantApplication(_ bundleId: String) -> Bool {
        return terminalBundleIds.contains(bundleId) ||
               bundleId.contains("claude") ||
               bundleId.contains("anthropic")
    }
}