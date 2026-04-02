---
phase: 03-dynamic-island-widget
plan: 02
type: execute
wave: 2
depends_on: [03-dynamic-island-widget-01]
files_modified:
  - VibeIsland/MenuBar/VibeIslandMenuBar.swift
  - VibeIslandTests/MenuBarManagerTests.swift
autonomous: false
requirements:
  - CORE-01
  - CORE-02
user_setup: []

must_haves:
  truths:
    - "当代理状态变为 awaiting_approval 时，菜单栏图标显示视觉提示（闪烁、颜色变化、徽章）"
    - "当代理状态变为 complete 时，菜单栏图标显示视觉提示（闪烁、颜色变化、徽章）"
    - "视觉提示自动触发，无需用户干预"
    - "用户可以手动点击查看详细信息"
  artifacts:
    - path: "VibeIsland/MenuBar/VibeIslandMenuBar.swift"
      provides: "MenuBarManager 状态变化监听"
      exports: ["MenuBarManager.handleAutoExpandStateChange", "MenuBarManager.shouldAutoExpand"]
    - path: "VibeIsland/MenuBar/CompactStatusView.swift"
      provides: "视觉提示功能（闪烁、颜色变化、徽章）"
      exports: ["CompactStatusView 视觉提示状态"]
  key_links:
    - from: "VibeIsland/MenuBar/VibeIslandMenuBar.swift"
      to: "NotificationCenter.default"
      via: "监听 agentStateDidChange 通知"
      pattern: "NotificationCenter\\.default\\.publisher\\(for: \\.agentStateDidChange\\)"
    - from: "VibeIsland/MenuBar/CompactStatusView.swift"
      to: "VibeIsland/Models/AgentState.swift"
      via: "检查状态是否为 awaiting_approval 或 complete"
      pattern: "status == \\.awaitingApproval.*status == \\.complete"
---

<objective>
实现 MenuBarExtra popover 的自动展开功能，当代理需要审批或完成时自动展开详细视图，确保用户不会错过重要状态变化。

Purpose: 提高用户体验，当代理状态变化到需要用户注意的状态（等待审批、完成）时，自动展开 popover 让用户第一时间看到详细信息。
Output: MenuBarManager 自动展开逻辑和相关测试。
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

@VibeIsland/Models/AgentState.swift
@VibeIsland/State/StateManager.swift
@VibeIsland/MenuBar/VibeIslandMenuBar.swift
@.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-01-SUMMARY.md

# Key Interfaces from Existing Code

From VibeIsland/Models/AgentState.swift:
```swift
enum AgentStatus: String, Codable, CaseIterable {
    case inProgress, complete, awaitingApproval
    var displayName: String { /* 返回中文显示文本 */ }
}
```

From VibeIsland/State/StateManager.swift:
```swift
extension Notification.Name {
    static let agentStateDidChange = Notification.Name("agentStateDidChange")
}
// userInfo 包含: "agentId", "oldStatus", "newStatus", "isNewAgent"
```

需要在 StateManager 中添加新的通知定义：
```swift
extension Notification.Name {
    static let showVisualPrompt = Notification.Name("showVisualPrompt")
}
```
</context>

<tasks>

<task type="auto">
  <name>Task 1: 实现 MenuBarManager 自动展开逻辑</name>
  <files>VibeIsland/MenuBar/VibeIslandMenuBar.swift</files>
  <read_first>
    - VibeIsland/MenuBar/VibeIslandMenuBar.swift（了解现有 MenuBarManager 结构）
    - VibeIsland/State/StateManager.swift（了解状态通知结构）
    - VibeIsland/Models/AgentState.swift（了解状态枚举）
    - .planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-RESEARCH.md（了解自动展开模式）
  </read_first>
  <action>
    修改 `VibeIsland/MenuBar/VibeIslandMenuBar.swift` 文件，实现自动展开逻辑：

1. **在 MenuBarManager 中添加自动展开属性**：
   - 添加 `@Published var shouldAutoExpand: Bool = true`（用户可配置的开关）
   - 添加 `private var lastAutoExpandTime: Date?`（记录上次自动展开时间）
   - 添加 `private let autoExpandMinInterval: TimeInterval = 5.0`（最小自动展开间隔，秒）

2. **实现 shouldAutoExpand 方法**：
   ```swift
   func shouldAutoExpand(newStatus: AgentStatus, oldStatus: AgentStatus?) -> Bool {
       // 检查自动展开开关
       guard shouldAutoExpand else { return false }

       // 检查是否为新代理（新代理不自动展开，避免干扰）
       guard oldStatus != nil else { return false }

       // 检查是否为需要自动展开的状态
       guard newStatus == .awaitingApproval || newStatus == .complete else { return false }

       // 检查频率限制
       if let lastTime = lastAutoExpandTime {
           let timeSinceLastExpand = Date().timeIntervalSince(lastTime)
           guard timeSinceLastExpand >= autoExpandMinInterval else { return false }
       }

       return true
   }
   ```

3. **实现 handleAutoExpandStateChange 方法**：
   ```swift
   func handleAutoExpandStateChange(notification: Notification) {
       guard let agentId = notification.userInfo?["agentId"] as? String,
             let newStatusString = notification.userInfo?["newStatus"] as? String,
             let newStatus = AgentStatus(rawValue: newStatusString),
             let oldStatusString = notification.userInfo?["oldStatus"] as? String,
             let oldStatus = AgentStatus(rawValue: oldStatusString) else {
           return
       }

       // 检查是否应该触发视觉提示
       if shouldAutoExpand(newStatus: newStatus, oldStatus: oldStatus) {
           // 设置视觉提示标志（将在 CompactStatusView 中使用）
           NotificationCenter.default.post(
               name: .showVisualPrompt,
               object: nil,
               userInfo: ["status": newStatusString, "agentId": agentId]
           )

           print("🚀 显示视觉提示（代理：\(agentId)，状态：\(newStatus.displayName)）")
       }
   }
   ```

4. **在 MenuBarManager.init() 中监听通知**：
   - 添加对 `.agentStateDidChange` 通知的监听
   - 使用 `sink` 订阅通知，调用 `handleAutoExpandStateChange`
  </action>
  <verify>
    <automated>xcodebuild -scheme VibeIsland -destination 'platform=macOS' build</automated>
  </verify>
  <done>
    - MenuBarManager 包含 shouldAutoExpand 和 handleAutoExpandStateChange 方法
    - 自动展开逻辑正确检查状态和频率限制
    - 构建成功，无编译错误
  </done>
</task>

<task type="auto">
  <name>Task 2: 实现视觉提示作为自动展开替代方案</name>
  <files>VibeIsland/MenuBar/CompactStatusView.swift</files>
  <read_first>
    - VibeIsland/MenuBar/CompactStatusView.swift（了解现有紧凑视图结构）
    - VibeIsland/State/StateManager.swift（了解状态管理）
    - VibeIsland/Models/AgentState.swift（了解状态模型）
  </read_first>
  <action>
    修改 `VibeIsland/MenuBar/CompactStatusView.swift` 文件，实现视觉提示功能：

1. **添加视觉提示状态**：
   - 在 CompactStatusView 中添加 `@State private var hasNewImportantState: Bool = false`
   - 添加 `@State private var isBlinking: Bool = false`（用于闪烁效果）

2. **监听重要状态变化**：
   - 使用 `.onReceive(NotificationCenter.default.publisher(for: .agentStateDidChange))` 监听状态变化
   - 检查新状态是否为 `.awaitingApproval` 或 `.complete`
   - 如果是重要状态，设置 `hasNewImportantState = true` 和 `isBlinking = true`
   - 3秒后自动重置为 `false`

3. **实现闪烁动画**：
   ```swift
   .animation(
       hasNewImportantState ? Animation.easeInOut(duration: 0.5).repeatCount(3) : .default,
       value: isBlinking
   )
   ```

4. **修改图标样式**：
   - 当 `hasNewImportantState = true` 时：
     - 增大图标大小（从 22pt 到 24pt）
     - 改变图标颜色（从灰色到强调色）
     - 添加发光效果（`.shadow(color: .blue, radius: 5)`）
   - 闪烁效果应用到整个图标容器

5. **添加"待查看"徽章**：
   - 当 `hasNewImportantState = true` 时显示一个小徽章
   - 使用红色圆形背景 + 感叹号图标
   - 位置：图标右上角，偏移 2pt

**实现细节**：
- 闪烁动画：3 次，每次 0.5 秒（1.5秒总时长）
- 重置延迟：3 秒后自动隐藏视觉提示
- 颜色：等待审批使用 `.orange`，完成使用 `.green`
- 动画：使用 `accessibilityReducedMotion` 环境变量，用户启用减少动画时禁用闪烁
  </action>
  <verify>
    <automated>xcodebuild -scheme VibeIsland -destination 'platform=macOS' build</automated>
  </verify>
  <done>
    - CompactStatusView 包含视觉提示功能
    - 重要状态变化时图标闪烁并增大
    - 支持减少动画设置
    - 构建成功，无编译错误
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>MenuBarManager 自动展开逻辑和 CompactStatusView 视觉提示功能</what-built>
  <how-to-verify>
    1. 在 Xcode 中构建并运行应用
    2. 触发代理状态变为 awaiting_approval：
       - 验证菜单栏图标闪烁 3 次
       - 验证图标大小增大
       - 验证图标颜色变为橙色
       - 验证右上角显示"待查看"徽章
    3. 触发代理状态变为 complete：
       - 验证菜单栏图标闪烁 3 次
       - 验证图标颜色变为绿色
    4. 等待 3 秒：
       - 验证视觉提示自动消失
    5. 连续触发多次重要状态变化：
       - 验证视觉提示正确刷新
       - 验证闪烁动画流畅
    6. 在系统设置中启用"减少动画"：
       - 重新运行应用
       - 验证闪烁动画被禁用
       - 验证仍显示颜色变化和徽章
  </how-to-verify>
  <resume-signal>Type "approved" if visual prompts work correctly, or describe issues</resume-signal>
</task>

</tasks>

<verification>
- [ ] 代理状态变为 awaiting_approval 时显示视觉提示
- [ ] 代理状态变为 complete 时显示视觉提示
- [ ] 图标闪烁 3 次后自动停止
- [ ] 图标大小和颜色正确变化
- [ ] "待查看"徽章正确显示
- [ ] 减少动画设置被正确尊重
- [ ] 构建成功，无编译错误
</verification>

<success_criteria>
当代理状态变化到需要用户注意的状态时，菜单栏图标提供清晰的视觉提示（闪烁、颜色变化、徽章），引导用户查看详细信息。
</success_criteria>

<output>
After completion, create `.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-02-SUMMARY.md`
</output>