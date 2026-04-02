---
phase: 03-dynamic-island-widget
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - VibeIsland/MenuBar/VibeIslandMenuBar.swift
  - VibeIsland/MenuBar/CompactStatusView.swift
  - VibeIsland/MenuBar/ExpandedDetailsView.swift
autonomous: false
requirements:
  - DIUI-01
  - DIUI-02
  - DIUI-03
  - DIUI-04
  - STMG-03
user_setup: []

must_haves:
  truths:
    - "用户在菜单栏看到紧凑状态视图，显示活跃代理数量"
    - "用户点击菜单栏图标可以展开到详细视图"
    - "详细视图显示所有代理的状态信息"
    - "用户点击背景区域可以折叠展开视图"
    - "紧凑和展开状态之间有平滑动画过渡"
  artifacts:
    - path: "VibeIsland/MenuBar/VibeIslandMenuBar.swift"
      provides: "MenuBarExtra 入口点和状态管理"
      exports: ["VibeIslandMenuBar", "MenuBarManager"]
    - path: "VibeIsland/MenuBar/CompactStatusView.swift"
      provides: "菜单栏紧凑状态视图"
      exports: ["CompactStatusView"]
    - path: "VibeIsland/MenuBar/ExpandedDetailsView.swift"
      provides: "展开详细视图（Popover内容）"
      exports: ["ExpandedDetailsView"]
  key_links:
    - from: "VibeIsland/MenuBar/VibeIslandMenuBar.swift"
      to: "VibeIsland/State/StateManager.swift"
      via: "@ObservedObject StateManager.shared"
      pattern: "@ObservedObject.*StateManager"
    - from: "VibeIsland/MenuBar/ExpandedDetailsView.swift"
      to: "VibeIsland/Models/AgentState.swift"
      via: "AgentState 数组渲染"
      pattern: "ForEach.*agentStates"
    - from: "VibeIsland/MenuBar/CompactStatusView.swift"
      to: "VibeIsland/Models/AgentState.swift"
      via: "状态数量计算"
      pattern: "agentStates\\.count"
---

<objective>
构建基于 MenuBarExtra 的菜单栏 UI，实现紧凑状态视图和可展开的详细视图，提供动态岛式的用户体验。

Purpose: macOS 没有 Dynamic Island，使用 MenuBarExtra 作为替代方案，实现"一目了然"的代理状态监控体验。
Output: 完整的菜单栏 UI，包括状态指示图标、徽章显示和展开式 popover。
</objective>

<execution_context>
@/Users/Zhuanz/island/.claude/get-shit-done/workflows/execute-plan.md
@/Users/Zhuanz/island/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-RESEARCH.md
@.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-UI-SPEC.md

@VibeIsland/Models/AgentState.swift
@VibeIsland/State/StateManager.swift
@VibeIsland/VibeIslandApp.swift
@VibeIsland/SharedContainer/SharedContainer.swift
@.planning/phases/02-main-app-core/02-main-app-core-01-SUMMARY.md

# Key Interfaces from Existing Code

From VibeIsland/Models/AgentState.swift:
```swift
enum AgentStatus: String, Codable, CaseIterable {
    case inProgress, complete, awaitingApproval
    var displayName: String { /* 返回中文显示文本 */ }
}

struct AgentState: Codable, Identifiable, Equatable {
    let id: String
    let status: AgentStatus
    let terminalAppBundleId: String
    let terminalTabId: String?
    let lastUpdated: String
    var identifier: String { id }
}
```

From VibeIsland/State/StateManager.swift:
```swift
class StateManager: ObservableObject {
    static let shared = StateManager()
    @Published var agentStates: [AgentState] = []
    func getAgentStates() -> [AgentState]
    func getAgentCount(for status: AgentStatus) -> Int
    func hasAwaitingApprovalAgents() -> Bool
}
```
</context>

<tasks>

<task type="auto">
  <name>Task 1: 创建 MenuBarExtra 基础架构和 CompactStatusView</name>
  <files>VibeIsland/MenuBar/VibeIslandMenuBar.swift, VibeIsland/MenuBar/CompactStatusView.swift</files>
  <read_first>
    - VibeIsland/VibeIslandApp.swift（了解现有 App 结构）
    - VibeIsland/State/StateManager.swift（了解状态管理 API）
    - VibeIsland/Models/AgentState.swift（了解数据模型）
    - .planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-UI-SPEC.md（了解 UI 规范）
  </read_first>
  <action>
    ## 创建 VibeIslandMenuBar.swift

创建 `VibeIsland/MenuBar/VibeIslandMenuBar.swift` 文件，实现以下内容：

1. **MenuBarManager 类**：
   - 使用 `@Published var isPopoverExpanded = false` 控制 popover 展开状态
   - 监听 `.agentStateDidChange` 和 `.agentStatesDidChange` 通知
   - 实现 `handleStateChange(notification:)` 方法，当状态变化时更新 UI
   - 导出单例实例和 `isPopoverExpanded` 属性

2. **VibeIslandMenuBar View**：
   - 使用 `@ObservedObject` 引用 `StateManager.shared` 和 `MenuBarManager.shared`
   - 实现 `@main` App 结构，包含 `MenuBarExtra` scene
   - MenuBarExtra label 使用 `CompactStatusView()` 作为紧凑视图
   - MenuBarExtra content 使用 `ExpandedDetailsView()` 作为展开视图
   - 设置 `.menuBarExtraStyle(.window)` 以获得窗口式 popover 样式

## 创建 CompactStatusView.swift

创建 `VibeIsland/MenuBar/CompactStatusView.swift` 文件，实现以下内容：

1. **CompactStatusView 结构体**：
   - 接收 `@ObservedObject StateManager` 和 `@ObservedObject MenuBarManager` 参数
   - 使用 `HStack` 布局状态指示器和代理数量徽章
   - 状态指示器：使用 `ZStack` 包含 2-3 个 `Circle()`，每个圆点对应不同状态的代理
     - in_progress: `.blue` 颜色
     - complete: `.green` 颜色
     - awaiting_approval: `.orange` 颜色
     - 圆点大小：10pt，有活跃代理时显示，无活跃代理时隐藏
   - 代理数量徽章：
     - 当 `agentStates.count > 0` 时显示
     - 使用 `Text("\(agentStates.count)")` 显示数字
     - 字体：`.caption`，白色文字，红色圆形背景
     - 徽章大小：20pt，圆角矩形

2. **状态摘要逻辑**：
   - 当有等待审批的代理时，优先显示等待状态（橙色圆点）
   - 当有进行中的代理时，显示进行状态（蓝色圆点）
   - 当有完成的代理时，显示完成状态（绿色圆点）
   - 最多显示 3 个圆点，超过则按优先级排序

3. **图标样式**：
   - 无活跃代理时：显示灰色 "island" 图标
   - 有活跃代理时：显示状态圆点 + 数量徽章

**重要**：遵循 UI-SPEC.md 中的间距规范（4pt 网格系统），使用系统语义颜色（`.primary`, `.secondary`），所有文本使用中文。
  </action>
  <verify>
    <automated>xcodebuild -scheme VibeIsland -destination 'platform=macOS' build</automated>
  </verify>
  <done>
    - VibeIslandMenuBar.swift 文件存在且包含 MenuBarManager 和 VibeIslandMenuBar 结构
    - CompactStatusView.swift 文件存在且实现了状态指示器和数量徽章
    - 构建成功，无编译错误
  </done>
</task>

<task type="auto">
  <name>Task 2: 创建 ExpandedDetailsView（展开详细视图）</name>
  <files>VibeIsland/MenuBar/ExpandedDetailsView.swift</files>
  <read_first>
    - VibeIsland/State/StateManager.swift（了解状态管理 API）
    - VibeIsland/Models/AgentState.swift（了解数据模型）
    - VibeIsland/MenuBar/CompactStatusView.swift（了解紧凑视图实现）
    - .planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-UI-SPEC.md（了解 UI 规范）
  </read_first>
  <action>
    创建 `VibeIsland/MenuBar/ExpandedDetailsView.swift` 文件，实现以下内容：

1. **ExpandedDetailsView 结构体**：
   - 接收 `@ObservedObject StateManager` 和 `@ObservedObject MenuBarManager` 参数
   - 使用 `VStack` 布局标题栏、代理列表和页脚

2. **标题栏**：
   - 使用 `HStack` 包含标题和关闭按钮
   - 标题：`Text("Vibe Island")`，字体 `.headline`，颜色 `.primary`
   - 关闭按钮：`Button { isPopoverExpanded = false } label: { Image(systemName: "xmark.circle.fill") }`
   - 使用 `Spacer()` 推送标题到左侧，关闭按钮到右侧
   - 内边距：16pt（md）

3. **代理列表**：
   - 使用 `ScrollView` 包裹 `LazyVStack` 以支持滚动
   - 使用 `ForEach(stateManager.agentStates)` 遍历所有代理
   - 每个代理卡片使用 `HStack` 布局：
     - 左侧：状态指示圆点（10pt），根据状态设置颜色
     - 中间：代理信息
       - `Text("代理 \(agent.id)")`，字体 `.body`，颜色 `.primary`
       - 如果有 `terminalTabId`，显示 `Text("标签页 \(agent.terminalTabId ?? "")")`，字体 `.caption`，颜色 `.secondary`
     - 右侧：状态标签
       - `Text(agent.status.displayName)`，字体 `.caption`，颜色 `.secondary`，圆角矩形背景
       - 等待审批：`.orange` 背景
       - 完成：`.green` 背景
       - 进行中：`.blue` 背景
   - 代理卡片内边距：12pt，卡片之间间距：8pt（sm）
   - 添加 `Divider()` 分隔每个代理卡片

4. **空状态视图**：
   - 当 `agentStates.isEmpty` 时显示
   - 使用 `VStack` 居中显示空状态图标和文本
   - 图标：`Image(systemName: "tray")`，40pt，`.secondary` 颜色
   - 文本：`Text("无活跃代理")`，字体 `.body`，`.secondary` 颜色
   - 内边距：32pt（xl）

5. **页脚（可选）**：
   - 显示总代理数统计：`Text("共 \(agentStates.count) 个代理")`，字体 `.caption`，`.secondary` 颜色
   - 内边距：12pt

6. **样式和布局**：
   - Popover 最小宽度：280pt
   - Popover 最大高度：400pt（超出滚动）
   - 使用 `frame(minWidth: 280, idealWidth: 320, maxWidth: 400, minHeight: 200, idealHeight: 300, maxHeight: 500)`
   - 背景色：使用系统默认 popover 背景

**重要**：遵循 UI-SPEC.md 中的间距规范，使用系统语义颜色，所有文本使用中文。
  </action>
  <verify>
    <automated>xcodebuild -scheme VibeIsland -destination 'platform=macOS' build</automated>
  </verify>
  <done>
    - ExpandedDetailsView.swift 文件存在且实现了完整的展开视图
    - 支持空状态视图和代理列表显示
    - 构建成功，无编译错误
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>完整的 MenuBarExtra UI，包括 CompactStatusView（菜单栏紧凑视图）和 ExpandedDetailsView（展开详细视图）</what-built>
  <how-to-verify>
    1. 在 Xcode 中构建并运行 VibeIsland 应用
    2. 验证菜单栏图标显示：
       - 无活跃代理时：显示灰色 "island" 图标
       - 有活跃代理时：显示状态圆点 + 数量徽章
    3. 点击菜单栏图标，验证 popover 展开：
       - 标题栏显示 "Vibe Island" 和关闭按钮
       - 代理列表显示所有代理的状态信息
       - 空状态时显示 "无活跃代理"
    4. 点击背景区域，验证 popover 自动关闭
    5. 多次点击展开/关闭，验证交互流畅
    6. 测试多个代理（3个以上），验证滚动功能正常
  </how-to-verify>
  <resume-signal>Type "approved" if the UI works as expected, or describe issues</resume-signal>
</task>

</tasks>

<verification>
- [ ] 菜单栏图标正确显示状态和数量
- [ ] 点击菜单栏图标可以展开 popover
- [ ] Popover 显示所有代理的详细信息
- [ ] 点击背景区域可以关闭 popover
- [ ] 空状态正确显示
- [ ] 多个代理时滚动正常
- [ ] 构建成功，无编译错误
</verification>

<success_criteria>
用户可以通过菜单栏图标查看所有代理的紧凑状态和详细信息，展开/折叠交互流畅，空状态处理正确。
</success_criteria>

<output>
After completion, create `.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-01-SUMMARY.md`
</output>