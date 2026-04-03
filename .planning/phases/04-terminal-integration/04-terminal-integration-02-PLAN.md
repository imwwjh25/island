---
phase: 04-terminal-integration
plan: 02
type: execute
wave: 2
depends_on: [04-terminal-integration-01]
files_modified: [VibeIsland/MenuBar/ExpandedDetailsView.swift]
autonomous: false
requirements: [CORE-03, CORE-04]

must_haves:
  truths:
    - "用户点击代理卡片时，触发终端跳转逻辑"
    - "跳转成功时，终端应用激活并显示对应标签页"
    - "跳转失败时，显示友好的错误提示"
    - "错误提示清晰告知用户失败原因"
  artifacts:
    - path: "VibeIsland/MenuBar/ExpandedDetailsView.swift"
      provides: "代理卡片的点击交互和错误反馈"
      exports: ["agentCard 方法", ".onTapGesture 处理", "showAlert 警告显示"]
  key_links:
    - from: "ExpandedDetailsView.agentCard"
      to: "TerminalController.jumpToTab"
      via: "onTapGesture 调用"
      pattern: "TerminalController.shared.jumpToTab\\(terminal: type, tabId: tabId\\)"

    - from: "ExpandedDetailsView.agentCard"
      to: "TerminalController.isTerminalRunning"
      via: "调用前检查"
      pattern: "TerminalController.shared.isTerminalRunning\\(type\\)"

    - from: "ExpandedDetailsView.agentCard"
      to: "SwiftUI Alert"
      via: "错误状态触发"
      pattern: "\\$showAlert.*toggle\\(\\)"
---

<objective>
在 ExpandedDetailsView 中添加代理卡片点击交互和错误反馈

目的：用户可以通过点击代理卡片跳转到对应的终端标签页，失败时看到友好的错误提示

输出：Updated ExpandedDetailsView.swift，包含点击交互和错误处理
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
@VibeIsland/Terminal/TerminalController.swift
@VibeIsland/MenuBar/ExpandedDetailsView.swift

# Phase 03 实现的 ExpandedDetailsView 模式
</context>

<tasks>

<task type="auto">
  <name>任务 1: 添加状态变量和终端跳转方法</name>
  <files>VibeIsland/MenuBar/ExpandedDetailsView.swift</files>
  <read_first>
    - VibeIsland/MenuBar/ExpandedDetailsView.swift（了解当前结构）
    - VibeIsland/Models/AgentState.swift（了解 terminalAppBundleId 字段）
    - VibeIsland/Terminal/TerminalController.swift（了解可用的方法）
  </read_first>
  <action>
在 ExpandedDetailsView 中添加以下状态变量和方法：

**添加状态变量**（在 @ObservedObject 声明之后）：
```swift
/// 是否显示错误警告
@State private var showAlert = false

/// 错误消息
@State private var errorMessage = ""
```

**添加终端跳转方法**（在 agentCard 方法之前）：
```swift
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
```
  </action>
  <verify>
    <automated>xcodebuild build -scheme VibeIsland -destination 'platform=macOS' | grep -E "(error:|warning:|BUILD SUCCEEDED)"</automated>
  </verify>
  <done>
    showAlert 和 errorMessage 状态变量已添加
    jumpToTerminalTab(for:) 方法已实现
    方法检查终端应用信息和标签页 ID
    方法根据 Bundle ID 识别终端类型
    方法检查终端应用是否运行
    方法执行跳转并处理错误
    所有错误消息使用中文
  </done>
</task>

<task type="auto">
  <name>任务 2: 在代理卡片上添加点击交互和错误警告</name>
  <files>VibeIsland/MenuBar/ExpandedDetailsView.swift</files>
  <read_first>
    - VibeIsland/MenuBar/ExpandedDetailsView.swift（读取 agentCard 方法）
  </read_first>
  <action>
修改 agentCard 方法，添加点击交互和警告：

**在 agentCard 方法中添加 onTapGesture**（在整个 HStack 的 .padding 之后）：
```swift
.onTapGesture {
    jumpToTerminalTab(for: agent)
}
```

**在 agentCard 方法的 .accessibilityAddTraits(.isStaticText) 之后添加**：
```swift
.accessibilityAddTraits(.isButton)
.accessibilityHint("点击跳转到标签页 \(agent.terminalTabId ?? "无")")
```

**在 body 的 VStack 添加 Alert 修饰符**（在最后的 .padding 之后）：
```swift
.alert("跳转失败", isPresented: $showAlert) {
    Button("确定", role: .cancel) { }
} message: {
    Text(errorMessage)
}
```
  </action>
  <verify>
    <automated>xcodebuild build -scheme VibeIsland -destination 'platform=macOS' | grep -E "(error:|warning:|BUILD SUCCEEDED)"</automated>
  </verify>
  <done>
    agentCard 已添加 .onTapGesture 处理点击
    点击时调用 jumpToTerminalTab(for:)
    添加了 .accessibilityAddTraits(.isButton) 和 .accessibilityHint
    Alert 修饰符已添加到 body
    Alert 标题为"跳转失败"，消息使用 errorMessage
    确定按钮使用 role: .cancel
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>任务 3: 人工验证终端跳转功能</name>
  <files>N/A (人工验证不修改文件)</files>
  <what-built>完整的终端跳转功能，包括：
1. TerminalController 终端控制器
2. ExpandedDetailsView 的点击交互
3. 错误处理和用户反馈</what-built>
  <how-to-verify>
    1. 在 Xcode 中构建并运行应用
    2. 打开 iTerm2，创建多个标签页
    3. 确保 Claude Code 正在运行且监控状态
    4. 点击菜单栏图标，查看代理列表
    5. 点击某个代理卡片，验证是否跳转到对应的 iTerm2 标签页
    6. 重复步骤 2-5，但使用 Terminal.app 替代 iTerm2
    7. 测试错误场景：
       a. 关闭终端应用后点击代理卡片，应显示"未运行"错误
       b. 使用不支持的终端应用，应显示"不支持"错误
    8. 测试辅助功能：启用 VoiceOver，验证按钮提示是否正确播报
  </how-to-verify>
  <resume-signal>输入 "approved" 确认功能正常，或描述问题以便修复</resume-signal>
  <action>人工验证需要用户在真实环境中测试终端跳转功能，包括 iTerm2 和 Terminal.app 两种终端类型，以及各种错误场景。</action>
  <verify>人工验证通过后，在对话中输入 "approved" 继续</verify>
  <done>用户在 Xcode 中构建并运行应用，成功测试终端跳转功能，包括：
- iTerm2 标签页跳转成功
- Terminal.app 标签页跳转成功
- 错误场景显示正确的提示消息
- VoiceOver 辅助功能正常</done>
</task>

</tasks>

<verification>
编译项目确保没有错误：
```bash
xcodebuild -scheme VibeIsland -destination 'platform=macOS' clean build
```

运行测试验证修改后的功能：
```bash
xcodebuild test -scheme VibeIsland -destination 'platform=macOS'
```

人工验证通过后，标记 Phase 4 计划完成。
</verification>

<success_criteria>
1. ExpandedDetailsView.swift 修改成功，编译通过
2. 代理卡片支持点击交互
3. 点击时正确调用 TerminalController.jumpToTab
4. 跳转成功时，终端应用激活并显示对应标签页
5. 跳转失败时，显示友好的错误提示
6. 错误提示清晰告知失败原因（未运行、不支持、找不到标签页等）
7. VoiceOver 正确播报按钮提示
8. 人工验证通过
</success_criteria>

<output>
完成后创建 `.planning/phases/04-terminal-integration/04-terminal-integration-02-SUMMARY.md`
</output>