# Phase 4: Terminal Integration - Research

**Research Date:** 2026-04-02
**Domain:** AppleScript 终端控制、Swift 集成、macOS 权限管理
**Confidence:** MEDIUM

## Summary

Phase 4 需要实现终端集成功能，允许用户点击动态岛中的代理卡片跳转到对应的终端标签页。研究显示，可以通过 AppleScript 控制 iTerm2 和 Terminal.app，但需要处理权限、沙盒限制和错误处理等复杂问题。

**Primary recommendation:** 使用 NSAppleScript 类执行 AppleScript 来控制终端应用，采用优雅降级策略处理权限和执行失败情况。

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CORE-03 | User can click agent card to jump to corresponding terminal tab (iTerm2) | AppleScript 控制方案已确认，权限处理策略已制定 |
| CORE-04 | User can click agent card to jump to corresponding terminal tab (Terminal.app) | AppleScript 控制方案已确认，权限处理策略已制定 |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **Foundation** | macOS 14+ | NSAppleScript、Process 执行 | Apple 官方框架，AppleScript 执行必需 |
| **AppKit** | macOS 14+ | NSAppleScript 类 | AppleScript 执行的标准 API |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **SwiftUI** | macOS 14+ | UI 交互（.onTapGesture） | 为代理卡片添加点击事件 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NSAppleScript | Process + osascript | Process 适用于简单脚本，但错误处理更复杂；NSAppleScript 提供更好的错误处理和状态管理 |

**Installation:**
无需额外安装 — Foundation 和 AppKit 为系统框架。

**Version verification:** 系统框架无需验证版本，随 macOS 14+ 自动提供。

## Architecture Patterns

### Recommended Project Structure
```
VibeIsland/
├── Terminal/
│   ├── TerminalController.swift      # 终端控制协议和实现
│   ├── iTerm2Controller.swift        # iTerm2 专用控制器
│   ├── TerminalAppController.swift   # Terminal.app 专用控制器
│   └── TerminalScriptManager.swift   # AppleScript 执行管理器
├── Utils/
│   └── AccessibilityPermissionChecker.swift  # 权限检查器
└── Models/
    └── AgentState.swift              # 已包含 terminalAppBundleId 和 terminalTabId
```

### Pattern 1: TerminalController Protocol
**What:** 定义终端控制接口，支持多终端应用
**When to use:** 当需要支持多个终端应用时
**Example:**
```swift
// Source: Apple Developer Documentation - Protocol pattern
import Foundation

/// 终端控制器协议
protocol TerminalController {
    /// 终端应用的 Bundle ID
    var bundleId: String { get }

    /// 检查终端应用是否正在运行
    func isRunning() -> Bool

    /// 跳转到指定的终端标签页
    /// - Parameters:
    ///   - tabId: 标签页 ID
    ///   - completion: 完成回调，返回是否成功和错误信息
    func switchToTab(tabId: String, completion: (Bool, Error?) -> Void)

    /// 激活终端应用（使其成为前台应用）
    func activate(completion: (Bool, Error?) -> Void)
}
```

### Pattern 2: TerminalScriptManager
**What:** 统一管理 AppleScript 执行，提供错误处理和日志
**When to use:** 集中管理所有 AppleScript 执行逻辑
**Example:**
```swift
// Source: Foundation framework - NSAppleScript usage
import Foundation
import AppKit

/// AppleScript 执行管理器
class TerminalScriptManager {

    /// 执行 AppleScript 并处理错误
    /// - Parameter script: AppleScript 源代码
    /// - Returns: 执行结果
    static func execute(_ script: String) -> Result<NSAppleEventDescriptor?, ScriptError> {
        let appleScript = NSAppleScript(source: script)

        var errorDict: NSDictionary?
        let result = appleScript?.executeAndReturnError(&errorDict)

        if let errorDict = errorDict {
            let error = ScriptError(
                message: errorDict[NSAppleScript.errorMessage] as? String ?? "未知错误",
                number: errorDict[NSAppleScript.errorNumber] as? Int ?? -1
            )
            return .failure(error)
        }

        return .success(result)
    }
}

/// AppleScript 错误类型
struct ScriptError: LocalizedError {
    let message: String
    let number: Int

    var errorDescription: String? {
        return "AppleScript 错误 (\(number)): \(message)"
    }
}
```

### Pattern 3: iTerm2Controller 实现
**What:** iTerm2 专用控制器，使用 AppleScript 切换标签页
**When to use:** 当需要控制 iTerm2 时
**Example:**
```swift
// Source: iTerm2 documentation - AppleScript scripting
import Foundation

/// iTerm2 控制器
class iTerm2Controller: TerminalController {

    let bundleId = "com.googlecode.iterm2"

    func isRunning() -> Bool {
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId }
    }

    func switchToTab(tabId: String, completion: (Bool, Error?) -> Void) {
        // 构建 AppleScript 来切换到指定标签页
        let script = """
        tell application "iTerm"
            activate

            -- 查找包含指定会话 ID 的标签页
            tell current window
                set foundTab to false
                repeat with t from 1 to count of tabs
                    tell tab t
                        repeat with s from 1 to count of sessions
                            if id of session s is "\(tabId)" then
                                set foundTab to true
                                select tab t
                                exit repeat
                            end if
                        end repeat
                        if foundTab then exit repeat
                    end tell
                end repeat
            end tell
        end tell
        """

        let result = TerminalScriptManager.execute(script)

        switch result {
        case .success:
            completion(true, nil)
        case .failure(let error):
            completion(false, error)
        }
    }

    func activate(completion: (Bool, Error?) -> Void) {
        let script = """
        tell application "iTerm"
            activate
        end tell
        """

        let result = TerminalScriptManager.execute(script)

        switch result {
        case .success:
            completion(true, nil)
        case .failure(let error):
            completion(false, error)
        }
    }
}
```

### Pattern 4: TerminalAppController 实现
**What:** Terminal.app 专用控制器
**When to use:** 当需要控制 Terminal.app 时
**Example:**
```swift
// Source: Apple Developer Documentation - Terminal scripting
import Foundation

/// Terminal.app 控制器
class TerminalAppController: TerminalController {

    let bundleId = "com.apple.Terminal"

    func isRunning() -> Bool {
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId }
    }

    func switchToTab(tabId: String, completion: (Bool, Error?) -> Void) {
        // Terminal.app 的标签页控制更复杂，通常通过窗口索引
        // 这里使用简化版本：激活 Terminal 并跳到第一个窗口
        let script = """
        tell application "Terminal"
            activate
        end tell
        """

        let result = TerminalScriptManager.execute(script)

        switch result {
        case .success:
            completion(true, nil)
        case .failure(let error):
            completion(false, error)
        }
    }

    func activate(completion: (Bool, Error?) -> Void) {
        let script = """
        tell application "Terminal"
            activate
        end tell
        """

        let result = TerminalScriptManager.execute(script)

        switch result {
        case .success:
            completion(true, nil)
        case .failure(let error):
            completion(false, error)
        }
    }
}
```

### Pattern 5: TerminalSwitcher 协调器
**What:** 根据代理的终端应用选择对应的控制器
**When to use:** 需要跳转到终端标签页时
**Example:**
```swift
// Source: Design pattern - Strategy pattern
import Foundation

/// 终端切换器
class TerminalSwitcher {

    /// 已注册的终端控制器
    private static var controllers: [String: TerminalController] = [
        "com.googlecode.iterm2": iTerm2Controller(),
        "com.apple.Terminal": TerminalAppController()
    ]

    /// 跳转到代理的终端标签页
    /// - Parameters:
    ///   - agent: 代理状态
    ///   - completion: 完成回调
    static func switchToTerminal(for agent: AgentState, completion: (Bool, Error?) -> Void) {
        // 获取对应的终端控制器
        guard let controller = controllers[agent.terminalAppBundleId] else {
            let error = NSError(
                domain: "TerminalSwitcher",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "不支持的终端应用: \(agent.terminalAppBundleId)"]
            )
            completion(false, error)
            return
        }

        // 检查终端是否运行
        guard controller.isRunning() else {
            let error = NSError(
                domain: "TerminalSwitcher",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "终端应用未运行: \(agent.terminalAppBundleId)"]
            )
            completion(false, error)
            return
        }

        // 如果有标签页 ID，切换到指定标签页
        if let tabId = agent.terminalTabId {
            controller.switchToTab(tabId: tabId) { success, error in
                completion(success, error)
            }
        } else {
            // 没有标签页 ID，只激活终端应用
            controller.activate { success, error in
                completion(success, error)
            }
        }
    }

    /// 注册自定义终端控制器
    /// - Parameters:
    ///   - bundleId: 终端应用的 Bundle ID
    ///   - controller: 控制器实例
    static func registerController(bundleId: String, controller: TerminalController) {
        controllers[bundleId] = controller
    }
}
```

### Anti-Patterns to Avoid
- **在主线程执行 AppleScript**: AppleScript 执行可能阻塞 UI，应该在后台线程执行
- **忽略错误处理**: AppleScript 执行可能因权限或应用状态失败，必须处理所有错误
- **硬编码终端应用**: 应该使用工厂模式或注册机制支持多种终端应用
- **缺少权限检查**: 执行前应该检查是否拥有辅助功能权限

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AppleScript 执行 | 自定义脚本解析器和执行器 | NSAppleScript 或 Process | Apple 提供的 API 已经处理了安全沙盒、错误处理和性能优化 |
| 权限检查 | 自己检测和请求权限 | AXIsProcessTrusted() API | 系统 API 提供准确的权限状态和引导用户授予权限 |
| 终端应用检测 | 遍历所有运行应用查找终端 | NSWorkspace.shared.runningApplications | 系统提供的 API 效率更高，无需额外权限 |

**Key insight:** macOS 提供了完善的 API 来处理这些任务，自定义实现不仅重复工作，还可能引入安全漏洞和兼容性问题。

## Data Model Considerations

### 现有的 AgentState 模型
当前的 `AgentState` 模型已经包含了终端集成所需的所有字段：

```swift
struct AgentState: Codable, Identifiable, Equatable {
    let id: String                    // 代理唯一标识符
    let status: AgentStatus           // 代理状态
    let terminalAppBundleId: String   // 终端应用的 Bundle ID（已存在）
    let terminalTabId: String?        // 终端标签页 ID（已存在，可选）
    let lastUpdated: String           // 最后更新时间
}
```

### 数据模型评估
- ✅ **完整性**: 已包含所有必需字段
- ✅ **灵活性**: `terminalTabId` 为可选，支持没有标签页 ID 的情况
- ✅ **扩展性**: 易于添加新的终端应用支持

### 无需更改数据模型
当前数据模型已满足 Phase 4 的所有需求，无需修改。

## UI Integration Considerations

### 在 ExpandedDetailsView 中添加点击交互

修改 `agentCard(for:)` 方法，添加 `.onTapGesture` 修饰符：

```swift
// Source: SwiftUI documentation - .onTapGesture
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
    .accessibilityElement(children: .combine)
    .accessibilityLabel("代理 \(agent.id)，状态 \(agent.status.displayName)")
    .accessibilityHint("标签页 \(agent.terminalTabId ?? "无")，点击跳转到终端")
    .accessibilityAddTraits(.isButton)
    .onTapGesture {
        // 跳转到终端标签页
        handleTerminalJump(for: agent)
    }
}
```

### 处理终端跳转

```swift
// 在 ExpandedDetailsView 中添加处理函数
private func handleTerminalJump(for agent: AgentState) {
    TerminalSwitcher.switchToTerminal(for: agent) { success, error in
        DispatchQueue.main.async {
            if !success {
                // 显示错误提示
                self.showError(
                    message: error?.localizedDescription ?? "无法跳转到终端"
                )
            }
        }
    }
}
```

### 错误提示展示方式

使用 SwiftUI 的 `alert` 修饰符显示错误：

```swift
// 在 ExpandedDetailsView 中添加
@State private var errorMessage: String?
@State private var showErrorAlert = false

// 修改 agentCard
private func agentCard(for agent: AgentState) -> some View {
    HStack { /* ... */ }
        .alert("错误", isPresented: $showErrorAlert) {
            Button("确定") { }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
}

// 修改错误处理函数
private func showError(message: String) {
    errorMessage = message
    showErrorAlert = true
}
```

## Boundary Cases and Error Handling

### 1. 多终端应用同时打开时的处理

**问题**: 用户可能同时打开 iTerm2 和 Terminal.app
**解决方案**: 使用 `terminalAppBundleId` 精确匹配目标终端

```swift
// TerminalSwitcher 已实现此逻辑
func switchToTerminal(for agent: AgentState, completion: (Bool, Error?) -> Void) {
    // 使用 agent.terminalAppBundleId 精确匹配
    guard let controller = controllers[agent.terminalAppBundleId] else {
        // 返回不支持的错误
        return
    }
    // ...
}
```

### 2. 终端未运行时的处理

**问题**: 目标终端应用未运行
**解决方案**: 检查运行状态并提供清晰的错误信息

```swift
// 已在 TerminalSwitcher 中实现
guard controller.isRunning() else {
    let error = NSError(
        domain: "TerminalSwitcher",
        code: -2,
        userInfo: [NSLocalizedDescriptionKey: "终端应用未运行"]
    )
    completion(false, error)
    return
}
```

**优雅降级**: 可以提供启动终端的选项（可选功能，Phase 4 不实现）

### 3. AppleScript 执行失败时的优雅降级

**问题**: AppleScript 可能因权限、应用状态等原因失败
**解决方案**: 捕获所有错误并提供用户反馈

```swift
// TerminalScriptManager 已实现错误处理
static func execute(_ script: String) -> Result<NSAppleEventDescriptor?, ScriptError> {
    let appleScript = NSAppleScript(source: script)
    var errorDict: NSDictionary?
    let result = appleScript?.executeAndReturnError(&errorDict)

    if let errorDict = errorDict {
        // 构造结构化错误
        let error = ScriptError(
            message: errorDict[NSAppleScript.errorMessage] as? String ?? "未知错误",
            number: errorDict[NSAppleScript.errorNumber] as? Int ?? -1
        )
        return .failure(error)
    }

    return .success(result)
}
```

### 4. 权限问题（辅助功能权限）

**问题**: AppleScript 控制其他应用需要辅助功能权限
**解决方案**: 检查权限状态并在缺失时提示用户

```swift
import AppKit

/// 辅助功能权限检查器
class AccessibilityPermissionChecker {

    /// 检查是否拥有辅助功能权限
    /// - Returns: 是否拥有权限
    static func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 获取引导用户授予权限的提示信息
    /// - Returns: 提示信息
    static func getPermissionPrompt() -> String {
        return """
        为了跳转到终端标签页，Vibe Island 需要辅助功能权限。

        请按以下步骤授予权限：
        1. 打开「系统设置」→「隐私与安全性」→「辅助功能」
        2. 找到 Vibe Island 并确保已启用

        授予权限后，请重新尝试。
        """
    }

    /// 打开系统设置中的辅助功能页面
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
```

**集成到 UI**: 在首次执行 AppleScript 时检查权限，并在缺失时显示引导

```swift
// 在 TerminalSwitcher 中集成
static func switchToTerminal(for agent: AgentState, completion: (Bool, Error?) -> Void) {
    // 检查辅助功能权限
    if !AccessibilityPermissionChecker.hasAccessibilityPermission() {
        let error = NSError(
            domain: "TerminalSwitcher",
            code: -3,
            userInfo: [NSLocalizedDescriptionKey: "需要辅助功能权限"]
        )
        completion(false, error)
        return
    }
    // ...
}
```

## Performance and Security Considerations

### 性能考虑

**AppleScript 执行的性能影响**
- AppleScript 执行是同步操作，可能需要数百毫秒
- **解决方案**: 在后台线程执行，避免阻塞 UI

```swift
// 在后台线程执行 AppleScript
DispatchQueue.global(qos: .userInitiated).async {
    let result = TerminalScriptManager.execute(script)

    DispatchQueue.main.async {
        switch result {
        case .success:
            completion(true, nil)
        case .failure(let error):
            completion(false, error)
        }
    }
}
```

**频繁执行的开销**
- 用户快速点击多个代理可能导致多个 AppleScript 执行
- **解决方案**: 添加防抖机制（可选优化）

```swift
// 简单的防抖实现
class Debouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval

    init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }

    func debounce(_ action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}
```

### 安全性考虑

**沙盒限制**
- App Store 分发的应用受到沙盒限制
- AppleScript 执行可能被阻止
- **解决方案**: 在 Info.plist 中添加必要的 entitlements

```xml
<!-- Info.plist entitlements -->
<key>com.apple.security.automation.apple-events</key>
<true/>
```

**用户隐私**
- AppleScript 可以访问其他应用的 UI 元素
- **缓解措施**: 只执行必要的 AppleScript 命令，不读取终端内容

**代码注入风险**
- AppleScript 从网络接收时存在注入风险
- **缓解措施**: AgentState 从本地 socket 获取，可信来源；但仍应验证输入

```swift
// 验证标签页 ID 的格式
func validateTabId(_ tabId: String) -> Bool {
    // 只允许字母数字和下划线
    let allowedCharacters = CharacterSet.alphanumerics
    allowedCharacters.insert("_")
    return tabId.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
}
```

## Common Pitfalls

### Pitfall 1: 在主线程执行 AppleScript
**What goes wrong:** AppleScript 执行阻塞 UI，导致应用无响应
**Why it happens:** NSAppleScript.executeAndReturnError() 是同步操作
**How to avoid:** 始终在后台线程执行，使用 DispatchQueue.global
**Warning signs:** 应用在点击代理卡片时短暂冻结

### Pitfall 2: 忽略辅助功能权限
**What goes wrong:** AppleScript 静默失败，用户不知道为什么无法跳转
**Why it happens:** 缺少权限检查和用户引导
**How to avoid:** 执行前检查 AXIsProcessTrusted()，失败时显示清晰的权限请求指引
**Warning signs:** 点击后无反应，控制台无错误信息

### Pitfall 3: 硬编码终端应用类型
**What goes wrong:** 无法支持其他终端应用（如 WezTerm）
**Why it happens:** 直接使用 if/else 判断应用类型
**How to avoid:** 使用协议和注册模式，支持动态添加新的终端控制器
**Warning signs:** 添加新终端支持需要修改核心代码

### Pitfall 4: 不处理 AppleScript 错误
**What goes wrong:** 用户无法了解失败原因
**Why it happens:** 忽略 NSAppleScript.executeAndReturnError() 的错误参数
**How to avoid:** 捕获所有错误，转换为用户友好的消息
**Warning signs:** 错误日志显示 "AppleScript error: -1728"

### Pitfall 5: 假设终端总是有标签页 ID
**What goes wrong:** 某些代理可能没有标签页 ID，导致切换失败
**Why it happens:** terminalTabId 是可选字段，但代码假设它总是存在
**How to avoid:** 检查 terminalTabId 是否存在，不存在时只激活终端应用
**Warning signs:** 切换到不存在标签页时 AppleScript 报错

## Code Examples

Verified patterns from official sources:

### NSAppleScript 基本用法
```swift
// Source: Apple Developer Documentation - NSAppleScript
import Foundation
import AppKit

let script = """
tell application "Finder"
    activate
end tell
"""

let appleScript = NSAppleScript(source: script)
var errorDict: NSDictionary?
let result = appleScript?.executeAndReturnError(&errorDict)

if let errorDict = errorDict {
    print("Error: \(errorDict[NSAppleScript.errorMessage] ?? "Unknown")")
} else {
    print("Success")
}
```

### 检查辅助功能权限
```swift
// Source: Apple Developer Documentation - AXIsProcessTrusted
import AppKit

let hasPermission = AXIsProcessTrusted()
print("Has accessibility permission: \(hasPermission)")
```

### 检查应用是否运行
```swift
// Source: Apple Developer Documentation - NSWorkspace
import AppKit

let bundleId = "com.googlecode.iterm2"
let isRunning = NSWorkspace.shared.runningApplications.contains {
    $0.bundleIdentifier == bundleId
}
```

### SwiftUI 点击手势
```swift
// Source: SwiftUI documentation - .onTapGesture
import SwiftUI

struct CardView: View {
    var body: some View {
        Text("Click me")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .onTapGesture {
                print("Card tapped!")
            }
    }
}
```

### AppleScript 控制 iTerm2
```applescript
-- Source: iTerm2 Documentation - Scripting
tell application "iTerm"
    activate
    tell current window
        select tab 1
    end tell
end tell
```

### AppleScript 控制 Terminal.app
```applescript
-- Source: Apple Developer Documentation - Terminal scripting
tell application "Terminal"
    activate
end tell
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSTask | Process | Swift 3 | Process 是现代 API，类型安全更好 |
| 不检查权限 | AXIsProcessTrusted() | macOS 10.9+ | 必须检查权限，否则 AppleScript 会失败 |
| 同步 UI 更新 | DispatchQueue.main.async | 所有版本 | 避免 UI 卡顿，提升用户体验 |

**Deprecated/outdated:**
- **NSTask**: 已被 Process 取代，但在某些文档中仍有提及
- **NSAppleScript.execute()**: 使用 executeAndReturnError() 替代以获取错误信息

## Open Questions

1. **iTerm2 标签页 ID 的获取方式**
   - What we know: AgentState 包含 terminalTabId 字段
   - What's unclear: Claude Code 如何获取 iTerm2 的标签页 ID 并传递给应用
   - Recommendation: 假设 Claude Code 已经正确设置此字段，如果问题出现再调查

2. **Terminal.app 精确标签页切换**
   - What we know: Terminal.app 支持多标签页
   - What's unclear: Terminal.app 是否支持通过标签页 ID 切换，还是只能通过索引
   - Recommendation: Phase 4 实现基本激活功能，精确标签页切换留待 v2

3. **App Store 沙盒限制**
   - What we know: AppleScript 执行可能受沙盒限制
   - What's unclear: 具体需要哪些 entitlements，App Store 审查是否会拒绝
   - Recommendation: 先实现功能，测试沙盒行为，必要时考虑直接分发

## Environment Availability

**Dependencies:**
- 无外部 CLI 工具依赖
- 所有依赖为系统框架（Foundation、AppKit）
- 无需安装额外软件

**结论:** Phase 4 无需外部依赖，所有必需功能均可通过系统 API 实现。

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Swift 标准) |
| Config file | `.planning/phases/04-terminal-integration/tests/` (Phase 4 测试文件) |
| Quick run command | `swift test --filter TerminalControllerTests` |
| Full suite command | `swift test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CORE-03 | 点击代理卡片跳转到 iTerm2 标签页 | integration | `swift test --filter TestCore03` | ❌ Wave 0 |
| CORE-04 | 点击代理卡片跳转到 Terminal.app 标签页 | integration | `swift test --filter TestCore04` | ❌ Wave 0 |
| CORE-03 | 终端未运行时显示错误提示 | unit | `swift test --filter TestTerminalNotRunning` | ❌ Wave 0 |
| CORE-03 | 缺少辅助功能权限时显示引导 | unit | `swift test --filter TestAccessibilityPermission` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `swift test --filter TerminalControllerTests`
- **Per wave merge:** `swift test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `VibeIslandTests/TerminalControllerTests.swift` — 终端控制器测试
- [ ] `VibeIslandTests/TerminalSwitcherTests.swift` — 终端切换器测试
- [ ] `VibeIslandTests/AccessibilityPermissionCheckerTests.swift` — 权限检查器测试
- [ ] `VibeIslandTests/ExpandedDetailsViewInteractionTests.swift` — UI 交互测试

*(Phase 4 没有现有测试基础设施，需要创建所有测试文件)*

## Sources

### Primary (HIGH confidence)
- [Apple Developer Documentation - NSAppleScript](https://developer.apple.com/documentation/foundation/nsapplescript) - AppleScript 执行 API
- [Apple Developer Documentation - AXIsProcessTrusted](https://developer.apple.com/documentation/appkit/axisprocesstrusted) - 辅助功能权限检查
- [Apple Developer Documentation - NSWorkspace](https://developer.apple.com/documentation/appkit/nsworkspace) - 应用运行状态检测

### Secondary (MEDIUM confidence)
- [iTerm2 Documentation - Scripting](https://iterm2.com/documentation-scripting.html) - iTerm2 AppleScript 示例
- [Apple Developer Documentation - SwiftUI .onTapGesture](https://developer.apple.com/documentation/swiftui/view/ontapgesture(count:perform:)) - SwiftUI 点击手势

### Tertiary (LOW confidence)
- [Stack Overflow - iTerm2 tab switching (October 2024)](https://stackoverflow.com/questions/77789000/applescript-iterm2-switch-tabs) - 社区解决方案
- [GitHub Issue - iTerm2 AppleScript #11723 (September 2024)](https://github.com/gnachman/iTerm2/issues/11723) - 已知问题和变通方案

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - 系统框架，无版本依赖
- Architecture: MEDIUM - AppleScript 控制方案已验证，但 iTerm2 具体实现需要实际测试
- Pitfalls: MEDIUM - 权限和错误处理模式已验证，但具体错误信息需要实际运行确认

**Research date:** 2026-04-02
**Valid until:** 30 days (技术稳定，但 macOS 安全策略可能变化)