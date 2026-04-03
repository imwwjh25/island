//
//  ProcessMonitor.swift
//  VibeIsland
//
//  进程监控器 - 检测活跃的 Claude Code 会话进程
//

import AppKit
import Foundation
import os.log
import Darwin

/// 进程监控器
/// 通过检测 Claude Code CLI 进程来识别活跃的会话
class ProcessMonitor {

    // MARK: - 属性

    /// 共享实例
    static let shared = ProcessMonitor()

    /// 日志器
    private let logger = Logger(subsystem: "com.vibeisland", category: "ProcessMonitor")

    /// 状态管理器引用
    private let stateManager = StateManager.shared

    /// 是否正在监控
    private var isMonitoring = false

    /// 监控间隔（秒）
    private let monitorInterval: TimeInterval = 3.0

    /// 监控定时器
    private var monitorTimer: Timer?

    /// 已知的 Claude 进程（PID -> AgentState）
    private var knownProcesses: [Int32: AgentState] = [:]

    // MARK: - 初始化

    private init() {}

    // MARK: - 监控控制

    /// 启动进程监控
    func start() {
        if isMonitoring { return }

        isMonitoring = true
        logger.info("🚀 进程监控已启动")

        // 立即执行一次检测
        checkClaudeProcesses()

        // 启动定时轮询
        startPolling()
    }

    /// 停止进程监控
    func stop() {
        if !isMonitoring { return }

        isMonitoring = false
        logger.info("⏹ 进程监控已停止")
        stopPolling()
    }

    // MARK: - 定时轮询

    /// 启动定时轮询
    private func startPolling() {
        monitorTimer = Timer.scheduledTimer(
            withTimeInterval: monitorInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkClaudeProcesses()
        }
    }

    /// 停止定时轮询
    private func stopPolling() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    // MARK: - 进程检测

    /// 检测 Claude Code 进程
    func checkClaudeProcesses() {
        writeLog("检查 Claude Code 进程...")

        var claudeProcesses: [ClaudeProcessInfo] = []

        // 使用 sysctl 获取进程列表（不依赖外部命令）
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0

        // 获取所需缓冲区大小
        sysctl(&mib, 4, nil, &size, nil, 0)

        // 分配缓冲区
        let processCount = size / MemoryLayout<kinfo_proc>.stride
        var processList = [kinfo_proc](repeating: kinfo_proc(), count: processCount)

        // 获取进程列表
        let result = sysctl(&mib, 4, &processList, &size, nil, 0)
        if result == 0 {
            writeLog("获取到 \(processCount) 个进程")

            for proc in processList {
                // 获取进程命令
                let pid = proc.kp_proc.p_pid
                let comm = withUnsafePointer(to: proc.kp_proc.p_comm) {
                    String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
                }

                // 检查是否是 node 进程（可能运行 Claude）
                if comm.contains("node") || comm.contains("claude") {
                    // 获取完整命令行参数
                    if let args = getProcessArguments(pid: pid) {
                        let fullCmd = args.joined(separator: " ")
                        if fullCmd.contains("claude") || fullCmd.contains("anthropic") {
                            writeLog("发现 Claude 进程: PID=\(pid), comm=\(comm)")
                            claudeProcesses.append(ClaudeProcessInfo(
                                pid: pid,
                                terminal: "tty",
                                command: fullCmd,
                                terminalBundleId: "com.apple.terminal"
                            ))
                        }
                    }
                }
            }
        } else {
            writeLog("sysctl 失败: \(result)")
        }

        writeLog("总共发现 \(claudeProcesses.count) 个 Claude 进程")

        // 更新状态
        var currentPIDs: Set<Int32> = []

        for processInfo in claudeProcesses {
            currentPIDs.insert(processInfo.pid)

            let isNew = !knownProcesses.keys.contains(processInfo.pid)

            if isNew {
                let agentState = createAgentState(from: processInfo)
                knownProcesses[processInfo.pid] = agentState
                stateManager.updateAgentState(agentState)
                writeLog("✅ 新 Claude 会话: PID \(processInfo.pid)")
            }
        }

        // 移除已结束的进程
        let removedPIDs = knownProcesses.keys.filter { !currentPIDs.contains($0) }
        for pid in removedPIDs {
            if let agentState = knownProcesses[pid] {
                stateManager.removeAgentState(id: agentState.id)
                writeLog("❌ Claude 会话已结束: PID \(pid)")
            }
            knownProcesses.removeValue(forKey: pid)
        }

        writeLog("StateManager 中: \(stateManager.agentStates.count)")
    }

    /// 获取进程命令行参数
    private func getProcessArguments(pid: Int32) -> [String]? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0

        // 获取所需缓冲区大小
        sysctl(&mib, 3, nil, &size, nil, 0)
        if size == 0 { return nil }

        // 分配缓冲区
        var buffer = [CChar](repeating: 0, count: size)

        // 获取参数
        let result = sysctl(&mib, 3, &buffer, &size, nil, 0)
        if result != 0 { return nil }

        // 解析参数
        // 前几个字节是 argc
        var argc: Int32 = 0
        memcpy(&argc, &buffer, MemoryLayout<Int32>.size)

        // 跳过 argc 和可执行路径
        var offset = MemoryLayout<Int32>.size
        while offset < size && buffer[offset] != 0 { offset += 1 }
        offset += 1  // 跳过 null

        // 跳过填充
        while offset < size && buffer[offset] == 0 { offset += 1 }

        // 解析参数
        var args: [String] = []
        while offset < size && args.count < 50 {
            let start = offset
            while offset < size && buffer[offset] != 0 { offset += 1 }
            if offset > start {
                let arg = String(cString: Array(buffer[start..<offset]))
                args.append(arg)
            }
            offset += 1
        }

        return args
    }

    /// 获取 Node 进程中运行 Claude 的
    private func getNodeProcesses() -> [ClaudeProcessInfo] {
        var processes: [ClaudeProcessInfo] = []

        writeLog("开始执行 pgrep node...")

        // 获取所有 node 进程
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-fl", "node"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            writeLog("pgrep 已启动")
            task.waitUntilExit()
            writeLog("pgrep 退出码: \(task.terminationStatus)")

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                writeLog("pgrep 输出: \(output.count) 字节, 内容: \(output.prefix(200))")
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("claude") {
                        writeLog("发现 node claude 进程: \(line)")
                        // 解析 pgrep 输出: "PID command"
                        let parts = line.split(separator: " ", maxSplits: 1)
                        if parts.count >= 2, let pid = Int32(parts[0]) {
                            processes.append(ClaudeProcessInfo(
                                pid: pid,
                                terminal: "unknown",
                                command: String(parts[1]),
                                terminalBundleId: "com.apple.terminal"
                            ))
                        }
                    }
                }
            }
        } catch {
            writeLog("pgrep 执行失败: \(error.localizedDescription)")
        }

        return processes
    }

    /// 使用 ps 命令获取进程
    private func getClaudeProcessesViaPS() -> [ClaudeProcessInfo] {
        var processes: [ClaudeProcessInfo] = []

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["aux"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if isClaudeProcess(line) {
                        if let processInfo = parseProcessLine(line) {
                            processes.append(processInfo)
                        }
                    }
                }
            }
        } catch {
            writeLog("ps 执行失败: \(error.localizedDescription)")
        }

        return processes
    }

    /// 写入日志文件
    private func writeLog(_ message: String) {
        let logPath = "/tmp/vibeisland_debug.log"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] \(message)\n"

        guard let data = logLine.data(using: .utf8) else { return }

        if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: data)
        }
    }

    /// 获取所有 Claude Code 进程
    private func getClaudeProcesses() -> [ClaudeProcessInfo] {
        var processes: [ClaudeProcessInfo] = []

        // 使用 ps 命令获取进程信息
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["aux"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                writeLog("ps 命令输出长度: \(output.count)")
                processes = parsePSOutput(output)
            }
        } catch {
            logger.error("执行 ps 命令失败: \(error.localizedDescription)")
            writeLog("执行 ps 命令失败: \(error.localizedDescription)")
        }

        return processes
    }

    /// 解析 ps 命令输出
    private func parsePSOutput(_ output: String) -> [ClaudeProcessInfo] {
        var processes: [ClaudeProcessInfo] = []

        let lines = output.components(separatedBy: .newlines)
        writeLog("解析 \(lines.count) 行输出")

        for line in lines {
            // 检测 Claude Code 进程
            // 匹配: node .../claude 或 claude 命令
            let isClaude = isClaudeProcess(line)
            if isClaude {
                writeLog("检测到 Claude 行: \(line.prefix(100))...")
            }

            guard isClaude else { continue }

            // 解析进程信息
            if let processInfo = parseProcessLine(line) {
                processes.append(processInfo)
                writeLog("解析成功: PID=\(processInfo.pid)")
            }
        }

        return processes
    }

    /// 检测是否是 Claude 进程
    private func isClaudeProcess(_ line: String) -> Bool {
        let lowercased = line.lowercased()

        // 检测 Claude Code CLI 特征
        let indicators = [
            "/claude",           // claude 命令路径
            "claude-code",       // claude-code 包
            "@anthropic/claude"  // npm 包名
        ]

        for indicator in indicators {
            if lowercased.contains(indicator) {
                return true
            }
        }

        return false
    }

    /// 解析进程行
    private func parseProcessLine(_ line: String) -> ClaudeProcessInfo? {
        // ps aux 输出格式:
        // USER   PID  %CPU %MEM  VSZ   RSS   TT    STAT  STARTED  TIME     COMMAND
        // Zhuanz 4297 2.8  2.1   77926788 347520 s002  S+    2:41下午  2:16.09  node /Users/.../claude

        let columns = line.split(separator: " ", omittingEmptySubsequences: true)

        guard columns.count >= 11 else { return nil }

        // 解析 PID
        guard let pid = Int32(columns[1]) else { return nil }

        // 解析终端 (TT 列)
        let terminal = String(columns[6])

        // 解析命令
        let command = columns[10...].joined(separator: " ")

        // 尝试获取父进程信息（终端应用）
        let terminalBundleId = getTerminalBundleId(forPID: pid)

        return ClaudeProcessInfo(
            pid: pid,
            terminal: terminal,
            command: String(command),
            terminalBundleId: terminalBundleId
        )
    }

    /// 获取进程的终端应用 Bundle ID
    private func getTerminalBundleId(forPID pid: Int32) -> String {
        // 获取进程的父进程
        let parentPID = getParentPID(pid)

        // 查找父进程对应的应用
        if let app = NSRunningApplication(processIdentifier: parentPID) {
            return app.bundleIdentifier ?? "unknown"
        }

        // 尝试通过终端标识查找
        // s002 -> Terminal.app 或 iTerm2
        return "com.apple.terminal" // 默认假设
    }

    /// 获取父进程 PID
    private func getParentPID(_ pid: Int32) -> Int32 {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-o", "ppid=", "-p", String(pid)]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let ppid = output.trimmingCharacters(in: .whitespacesAndNewlines)
                return Int32(ppid) ?? 0
            }
        } catch {
            logger.error("获取父进程失败: \(error.localizedDescription)")
        }

        return 0
    }

    /// 创建 AgentState
    private func createAgentState(from processInfo: ClaudeProcessInfo) -> AgentState {
        // 使用 PID 作为 Agent ID
        let agentId = "claude-\(processInfo.pid)"

        // 检测状态
        let status = detectStatus(from: processInfo.command)

        return AgentState(
            id: agentId,
            status: status,
            terminalAppBundleId: processInfo.terminalBundleId,
            terminalTabId: processInfo.terminal,
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )
    }

    /// 检测进程状态
    private func detectStatus(from command: String) -> AgentStatus {
        // 如果命令包含特定参数，可能表示特定状态
        let lowercased = command.lowercased()

        // 检测等待审批状态（如果命令行有特定标志）
        if lowercased.contains("--awaiting") || lowercased.contains("--waiting") {
            return .awaitingApproval
        }

        // 默认为进行中
        return .inProgress
    }

    /// 手动触发检测
    func manualCheck() {
        logger.info("手动触发进程检测")
        checkClaudeProcesses()
    }
}

/// Claude 进程信息
struct ClaudeProcessInfo {
    let pid: Int32
    let terminal: String
    let command: String
    let terminalBundleId: String
}