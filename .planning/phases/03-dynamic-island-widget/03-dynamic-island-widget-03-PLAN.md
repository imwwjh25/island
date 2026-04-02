---
phase: 03-dynamic-island-widget
plan: 03
type: execute
wave: 3
depends_on: [03-dynamic-island-widget-01, 03-dynamic-island-widget-02]
files_modified:
  - VibeIsland/MenuBar/CompactStatusView.swift
  - VibeIsland/MenuBar/ExpandedDetailsView.swift
  - VibeIsland/MenuBar/VibeIslandMenuBar.swift
autonomous: false
requirements:
  - ACCS-01
  - ACCS-02
  - ACCS-03
user_setup: []

must_haves:
  truths:
    - "VoiceOver 可以正确朗读紧凑视图内容"
    - "VoiceOver 可以正确朗读展开视图内容"
    - "UI 自动适应深色/浅色模式"
    - "减少动画设置被正确尊重"
    - "所有可交互元素都有适当的辅助功能标签"
  artifacts:
    - path: "VibeIsland/MenuBar/CompactStatusView.swift"
      provides: "紧凑视图的辅助功能支持"
      exports: [".accessibilityLabel", ".accessibilityHint", ".accessibilityAddTraits"]
    - path: "VibeIsland/MenuBar/ExpandedDetailsView.swift"
      provides: "展开视图的辅助功能支持"
      exports: [".accessibilityLabel", ".accessibilityHint", ".accessibilityAddTraits"]
    - path: "VibeIsland/MenuBar/VibeIslandMenuBar.swift"
      provides: "MenuBarExtra 的辅助功能支持"
      exports: [".accessibilityLabel", ".accessibilityHint"]
  key_links:
    - from: "VibeIsland/MenuBar/CompactStatusView.swift"
      to: "@Environment(\\.accessibilityReducedMotion)"
      via: "读取减少动画设置"
      pattern: "@Environment\\(\\\\\\.accessibilityReducedMotion\\)"
    - from: "VibeIsland/MenuBar/ExpandedDetailsView.swift"
      to: "@Environment(\\.colorScheme)"
      via: "读取系统外观设置"
      pattern: "@Environment\\(\\\\\\.colorScheme\\)"
    - from: "VibeIsland/MenuBar/CompactStatusView.swift"
      to: "VoiceOver"
      via: "提供辅助功能标签"
      pattern: "\\.accessibilityLabel\\("
---

<objective>
为 MenuBarExtra UI 添加完整的辅助功能支持，包括 VoiceOver 标签、深色/浅色模式适配和减少动画支持。

Purpose: 确保所有用户（包括使用辅助功能的用户）都能完整使用 Vibe Island，符合 Apple 辅助功能指南和 App Store 要求。
Output: 完整的辅助功能支持，包括 VoiceOver、颜色适配和动画控制。
</objective>

<execution_context>
@/Users/Zhuanz/island/.claude/get-shit-done/workflows/execute-plan.md
@/Users/Zhuanz/island/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-UI-SPEC.md

@VibeIsland/MenuBar/CompactStatusView.swift
@VibeIsland/MenuBar/ExpandedDetailsView.swift
@VibeIsland/MenuBar/VibeIslandMenuBar.swift
@VibeIsland/Models/AgentState.swift

# Key Interfaces from UI-SPEC

辅助功能规范：
- VoiceOver 文本："Vibe Island 动态岛，{N} 个代理活跃"
- 代理卡片："代理 {ID}，状态 {状态}"
- 状态标签："状态，{状态}"
- 使用语义颜色（`.primary`, `.secondary`）
- 检查 `@Environment(\\.accessibilityReducedMotion)`
</context>

<tasks>

<task type="auto">
  <name>Task 1: 为 CompactStatusView 添加辅助功能支持</name>
  <files>VibeIsland/MenuBar/CompactStatusView.swift</files>
  <read_first>
    - VibeIsland/MenuBar/CompactStatusView.swift（了解现有紧凑视图结构）
    - VibeIsland/State/StateManager.swift（了解状态管理）
    - VibeIsland/Models/AgentState.swift（了解状态模型）
    - .planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-UI-SPEC.md（了解辅助功能规范）
  </read_first>
  <action>
    修改 `VibeIsland/MenuBar/CompactStatusView.swift` 文件，添加完整的辅助功能支持：

1. **添加环境变量**：
   ```swift
   @Environment(\.accessibilityReducedMotion) var reducedMotion
   @Environment(\.colorScheme) var colorScheme
   ```

2. **为主容器添加辅助功能标签**：
   ```swift
   .accessibilityLabel("Vibe Island 动态岛，\(agentStates.count) 个代理活跃")
   .accessibilityHint("点击查看详情")
   .accessibilityAddTraits(.isButton)
   ```

3. **为状态圆点添加辅助功能标签**：
   - 如果有等待审批的代理：
     ```swift
     .accessibilityLabel("有 \(stateManager.getAgentCount(for: .awaitingApproval)) 个代理等待审批")
     ```
   - 如果有进行中的代理：
     ```swift
     .accessibilityLabel("有 \(stateManager.getAgentCount(for: .inProgress)) 个代理进行中")
     ```
   - 如果有完成的代理：
     ```swift
     .accessibilityLabel("有 \(stateManager.getAgentCount(for: .complete)) 个代理已完成")
     ```

4. **为数量徽章添加辅助功能标签**：
   ```swift
   .accessibilityLabel("\(agentStates.count) 个活跃代理")
   .accessibilityHidden(true) // 隐藏独立元素，合并到主容器标签
   ```

5. **修改动画以支持减少动画设置**：
   ```swift
   .animation(reducedMotion ? .none : .easeInOut(duration: 0.3), value: hasNewImportantState)
   .animation(reducedMotion ? .none : .easeInOut(duration: 0.2), value: isBlinking)
   ```

6. **使用语义颜色**：
   - 确保所有颜色使用系统语义颜色（`.primary`, `.secondary`, `.blue`, `.green`, `.orange`）
   - 不使用硬编码的 RGB 值
   - 系统会自动适配深色/浅色模式

7. **为空状态添加辅助功能标签**：
   ```swift
   .accessibilityLabel("无活跃代理")
   .accessibilityHint("点击查看应用详情")
   ```

**实现细节**：
- VoiceOver 标签使用中文
- 使用 `.accessibilityElement(children: .combine)` 合并子元素标签
- 确保所有交互元素都有 `.accessibilityAddTraits(.isButton)`
- 为重要元素添加 `.accessibilityHint` 提供操作提示
  </action>
  <verify>
    <automated>xcodebuild -scheme VibeIsland -destination 'platform=macOS' build</automated>
  </verify>
  <done>
    - CompactStatusView 包含完整的 VoiceOver 标签
    - 支持减少动画设置
    - 使用语义颜色适配深色/浅色模式
    - 构建成功，无编译错误
  </done>
</task>

<task type="auto">
  <name>Task 2: 为 ExpandedDetailsView 添加辅助功能支持</name>
  <files>VibeIsland/MenuBar/ExpandedDetailsView.swift</files>
  <read_first>
    - VibeIsland/MenuBar/ExpandedDetailsView.swift（了解现有展开视图结构）
    - VibeIsland/State/StateManager.swift（了解状态管理）
    - VibeIsland/Models/AgentState.swift（了解状态模型）
    - .planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-UI-SPEC.md（了解辅助功能规范）
  </read_first>
  <action>
    修改 `VibeIsland/MenuBar/ExpandedDetailsView.swift` 文件，添加完整的辅助功能支持：

1. **添加环境变量**：
   ```swift
   @Environment(\.accessibilityReducedMotion) var reducedMotion
   @Environment(\.colorScheme) var colorScheme
   ```

2. **为主容器添加辅助功能标签**：
   ```swift
   .accessibilityLabel("Vibe Island 详细视图")
   .accessibilityHint("显示所有代理状态，点击外部关闭")
   ```

3. **为标题栏添加辅助功能标签**：
   ```swift
   .accessibilityLabel("Vibe Island")
   .accessibilityAddTraits(.isHeader)
   ```

4. **为关闭按钮添加辅助功能标签**：
   ```swift
   .accessibilityLabel("关闭")
   .accessibilityHint("关闭详细视图")
   .accessibilityAddTraits(.isButton)
   ```

5. **为代理卡片添加辅助功能标签**：
   ```swift
   .accessibilityLabel("代理 \(agent.id)，状态 \(agent.status.displayName)")
   .accessibilityHint("标签页 \(agent.terminalTabId ?? "无")")
   .accessibilityAddTraits(.isStaticText)
   ```

6. **为状态标签添加辅助功能标签**：
   ```swift
   .accessibilityLabel("状态：\(agent.status.displayName)")
   .accessibilityHidden(true) // 隐藏独立元素，合并到代理卡片标签
   ```

7. **为空状态视图添加辅助功能标签**：
   ```swift
   .accessibilityLabel("无活跃代理")
   .accessibilityHint("当前没有运行中的 Claude Code 代理")
   ```

8. **为页脚添加辅助功能标签**：
   ```swift
   .accessibilityLabel("共 \(agentStates.count) 个代理")
   .accessibilityAddTraits(.isStaticText)
   .accessibilityHidden(agentStates.isEmpty) // 空状态时隐藏
   ```

9. **修改滚动视图的动画**：
   ```swift
   .animation(reducedMotion ? .none : .easeInOut(duration: 0.3), value: agentStates.count)
   ```

10. **使用语义颜色**：
    - 确保所有颜色使用系统语义颜色
    - 状态指示圆点使用 `.blue`、`.green`、`.orange`
    - 文本使用 `.primary` 和 `.secondary`
    - 系统会自动适配深色/浅色模式

11. **为 ScrollView 添加辅助功能标签**：
    ```swift
    .accessibilityLabel("代理列表")
    .accessibilityHint("垂直滚动查看所有代理")
    ```

**实现细节**：
- VoiceOver 标签使用中文
- 使用 `.accessibilityElement(children: .combine)` 合并子元素
- 为列表添加适当的滚动提示
- 确保空状态有清晰的描述
  </action>
  <verify>
    <automated>xcodebuild -scheme VibeIsland -destination 'platform=macOS' build</automated>
  </verify>
  <done>
    - ExpandedDetailsView 包含完整的 VoiceOver 标签
    - 支持减少动画设置
    - 使用语义颜色适配深色/浅色模式
    - 所有交互元素都有适当的标签和提示
    - 构建成功，无编译错误
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>CompactStatusView 和 ExpandedDetailsView 的完整辅助功能支持</what-built>
  <how-to-verify>
    ## VoiceOver 测试
    1. 启用 VoiceOver（Command + F5）
    2. 导航到菜单栏图标：
       - 验证 VoiceOver 朗读："Vibe Island 动态岛，X 个代理活跃"
       - 验证提示："点击查看详情"
    3. 点击展开详细视图：
       - 验证 VoiceOver 朗读："Vibe Island 详细视图"
       - 验证提示："显示所有代理状态，点击外部关闭"
    4. 导航到代理卡片：
       - 验证 VoiceOver 朗读："代理 X，状态 进行中" / "等待审批" / "已完成"
       - 验证标签页信息（如果有）
    5. 测试空状态：
       - 清除所有代理状态
       - 验证 VoiceOver 朗读："无活跃代理"
       - 验证提示："当前没有运行中的 Claude Code 代理"

    ## 深色/浅色模式测试
    6. 切换系统到深色模式（系统偏好设置 -> 外观）：
       - 验证所有文本可读（使用 semantic colors）
       - 验证状态圆点颜色清晰可见
       - 验证背景色适配深色模式
    7. 切换系统到浅色模式：
       - 验证所有文本可读
       - 验证状态圆点颜色清晰可见
       - 验证背景色适配浅色模式

    ## 减少动画测试
    8. 启用减少动画设置（系统偏好设置 -> 辅助功能 -> 显示）：
       - 验证展开/折叠动画被禁用
       - 验证视觉提示闪烁被禁用
       - 验证图标大小变化动画被禁用
    9. 禁用减少动画设置：
       - 验证所有动画恢复正常
  </how-to-verify>
  <resume-signal>Type "approved" if all accessibility features work correctly, or describe issues</resume-signal>
</task>

</tasks>

<verification>
- [ ] VoiceOver 正确朗读紧凑视图内容
- [ ] VoiceOver 正确朗读展开视图内容
- [ ] 所有交互元素都有适当的标签和提示
- [ ] UI 正确适配深色模式
- [ ] UI 正确适配浅色模式
- [ ] 减少动画设置被正确尊重
- [ ] 构建成功，无编译错误
</verification>

<success_criteria>
MenuBarExtra UI 完全符合 Apple 辅助功能指南，VoiceOver 用户可以完整使用所有功能，深色/浅色模式适配正确，减少动画设置被正确尊重。
</success_criteria>

<output>
After completion, create `.planning/phases/03-dynamic-island-widget/03-dynamic-island-widget-03-SUMMARY.md`
</output>