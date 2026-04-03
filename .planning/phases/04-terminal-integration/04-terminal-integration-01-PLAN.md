---
phase: 04-terminal-integration
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [VibeIsland/Terminal/TerminalController.swift]
autonomous: true
requirements: [CORE-03, CORE-04]

must_haves:
  truths:
    - "用户点击代理卡片时，iTerm2 跳转到对应的标签页"
    - "用户点击代理卡片时，Terminal.app 跳转到对应的标签页"
    - "当目标终端应用未运行时，提供友好的错误提示"
    - "当 AppleScript 执行失败时，显示错误消息"
  artifacts:
    - path: "VibeIsland/Terminal/TerminalController.swift"
      provides: "终端控制逻辑（iTerm2 和 Terminal.app）"
      exports: ["TerminalController.shared", "func jumpToTab(terminal: TerminalType, tabId: String)", "enum TerminalType"]
  key_links:
    - from: "ExpandedDetailsView"
      to: "TerminalController"
      via: "onTapGesture 调用"
      pattern: "TerminalController.shared.jumpToTab"
---

<objective>
创建终端控制器，实现 iTerm2 和 Terminal.app 的标签页跳转功能

目的：提供统一的终端控制接口，支持两种主流终端应用的标签页跳转

输出：TerminalController.swift 文件，封装 AppleScript 调用逻辑
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@VibeIsland/Models/AgentState.swift

# iTerm2 和 Terminal.app 的 AppleScript 参考
</context>

<tasks>

<task type="auto">
  <name>任务 1: 创建 TerminalController 终端控制器</name>
  <files>VibeIsland/Terminal/TerminalController.swift</files>
  <read_first>
    - VibeIsland/Models/AgentState.swift（了解 terminalAppBundleId 和 terminalTabId 字段）
  </read_first>
  <action>
创建 VibeIsland/Terminal/TerminalController.swift 文件，实现以下功能：

**TerminalType 枚举**：
```swift
enum TerminalType: String, CaseIterable {
    case iterm2 = "com.googlecode.iterm2"
    case terminal = "com.apple.terminal"

    var displayName: String {
        switch self {
        case .iterm2:
            return "iTerm2"
        case .terminal:
            return "Terminal.app"
        }
    }
}
```

**TerminalController 类**（单例模式）：
```swift
class TerminalController {
    static let shared = TerminalController()

    /// 跳转到指定的终端标签页
    /// - Parameters:
    ///   - type: 终端类型
    ///   - tabId: 标签页 ID
    /// - Returns: 是否跳转成功
    func jumpToTab(terminal type: TerminalType, tabId: String) -> Bool

    /// 检查终端应用是否运行
    /// - Parameter type: 终端类型
    /// - Returns: 是否运行
    func isTerminalRunning(_ type: TerminalType) -> Bool

    private init() {}
}
```

**jumpToTab 实现逻辑**：

1. 首先检查终端应用是否运行（使用 NSRunningApplication）
2. 如果未运行，返回 false（在 UI 层显示错误提示）
3. 根据 terminalType 构造对应的 AppleScript：
   - iTerm2: 使用 `tell application "iTerm2"` + `tell current window`
   - Terminal.app: 使用 `tell application "Terminal"` + `tell window 1`
4. 执行 AppleScript 跳转到指定标签页
5. 处理错误情况并返回布尔值

**AppleScript 模板**：

iTerm2 跳转逻辑：
```applescript
tell application "iTerm2"
    tell current window
        set selected tab to tab whose name contains "tabId"
    end tell
    activate
end tell
```

Terminal.app 跳转逻辑：
```applescript
tell application "Terminal"
    tell window 1
        set selected tab to tab whose name contains "tabId"
    end tell
    activate
end tell
```

**错误处理**：
- 使用 try-catch 捕获 NSAppleScript 执行错误
- 记录错误日志
- 返回 false 表示失败

**注意事项**：
- 所有代码注释使用中文
- 使用 Bundle ID（com.googlecode.iterm2, com.apple.terminal）匹配终端应用
- 激活终端应用（activate）确保标签页可见
- 使用 name contains 而非精确匹配（tabId 可能是名称的一部分）
  </action>
  <verify>
    <automated>xcodebuild test -scheme VibeIsland -destination 'platform=macOS' -only-testing:VibeIslandTests/TerminalControllerTests</automated>
  </verify>
  <done>
    TerminalController.swift 文件存在且编译通过
    包含 TerminalType 枚举和 TerminalController 单例
    jumpToTab 方法接受 TerminalType 和 tabId 参数
    isTerminalRunning 方法检查应用是否运行
    所有代码注释使用中文
  </done>
</task>

</tasks>

<verification>
编译项目确保没有错误：
```bash
xcodebuild -scheme VibeIsland -destination 'platform=macOS' clean build
```

运行测试验证 TerminalController 功能：
```bash
xcodebuild test -scheme VibeIsland -destination 'platform=macOS'
```
</verification>

<success_criteria>
1. TerminalController.swift 文件创建成功，编译通过
2. TerminalType 枚举包含 iTerm2 和 Terminal.app 两种类型
3. jumpToTab 方法可以执行 AppleScript 跳转到指定标签页
4. isTerminalRunning 方法可以检测终端应用是否运行
5. 所有代码注释使用中文
6. 测试用例覆盖正常和错误场景
</success_criteria>

<output>
完成后创建 `.planning/phases/04-terminal-integration/04-terminal-integration-01-SUMMARY.md`
</output>