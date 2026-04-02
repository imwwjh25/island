---
phase: 03-dynamic-island-widget
plan: 02
type: summary
status: complete
created: 2026-04-02
completed: 2026-04-02
---

# Plan 02: 视觉提示功能（自动展开的替代方案）

## Objective

实现视觉提示功能，当代理状态变化到需要用户注意的状态（等待审批、完成）时，提供清晰的视觉反馈。

## What Was Built

由于 macOS MenuBarExtra 不支持程序化展开 popover（这是 iOS Dynamic Island 的独占功能），我们实现了视觉提示作为替代方案：

### 1. StateManager.swift 更新

添加了新的通知定义：
```swift
extension Notification.Name {
    static let showVisualPrompt = Notification.Name("showVisualPrompt")
}
```

### 2. MenuBarManager.swift 更新

**shouldShowVisualPrompt 方法**：
- 检查是否为新代理（新代理不显示视觉提示）
- 检查状态是否为 `.awaitingApproval` 或 `.complete`
- 返回是否应该显示视觉提示

**handleStateChange 方法更新**：
- 检测需要视觉提示的状态变化
- 发布 `.showVisualPrompt` 通知，包含状态和代理 ID
- 打印调试信息

### 3. CompactStatusView.swift 更新

**视觉提示状态**：
- `@State private var hasNewImportantState = false` - 是否有新的重要状态
- `@State private var isBlinking = false` - 是否正在闪烁
- `@Environment(\.accessibilityReducedMotion) var reducedMotion` - 减少动画设置

**showVisualPrompt 方法**：
- 接收 `.showVisualPrompt` 通知
- 设置 `hasNewImportantState = true` 和 `isBlinking = true`
- 3 秒后自动重置为 `false`
- 如果启用减少动画，不执行闪烁效果

**视觉效果**：

1. **闪烁动画**：
   ```swift
   .animation(
       reducedMotion ? .none : Animation.easeInOut(duration: 0.5).repeatCount(3),
       value: isBlinking
   )
   ```

2. **图标大小变化**：
   - 正常状态：10pt 圆点
   - 重要状态：12pt 圆点（放大 1.2 倍）

3. **发光效果**：
   - 根据状态颜色添加发光效果
   - 等待审批：橙色
   - 完成：绿色
   - 进行中：蓝色

4. **"待查看"徽章**：
   - 红色圆形背景 + 感叹号图标
   - 显示在徽章右上角，偏移 (8, -8)

**实现细节**：
- 闪烁动画：3 次，每次 0.5 秒（1.5 秒总时长）
- 重置延迟：3 秒后自动隐藏视觉提示
- 颜色：等待审批使用 `.orange`，完成使用 `.green`
- 动画：使用 `accessibilityReducedMotion` 环境变量，用户启用减少动画时禁用闪烁

## Files Modified

```
VibeIsland/State/StateManager.swift      (添加 showVisualPrompt 通知)
VibeIsland/MenuBar/VibeIslandMenuBar.swift  (实现视觉提示逻辑)
VibeIsland/MenuBar/CompactStatusView.swift (实现视觉效果)
```

## Technical Decisions

**为什么使用视觉提示而非自动展开？**

根据研究文档（03-dynamic-island-widget-RESEARCH.md）：
- **Dynamic Island 是 iOS 独占功能** - macOS 上不存在对应的 API
- **MenuBarExtra 不支持程序化展开** - macOS 的 MenuBarExtra popover 只能通过用户点击展开
- **视觉提示是有效替代** - 提供足够的状态变化反馈，引导用户查看详细信息

## User Verification Needed

请在 Xcode 中构建并运行应用，验证以下功能：

1. **等待审批状态**：
   - 触发代理状态变为 awaiting_approval
   - 验证菜单栏图标闪烁 3 次
   - 验证图标大小增大到 12pt
   - 验证图标颜色变为橙色
   - 验证右上角显示"待查看"徽章

2. **完成状态**：
   - 触发代理状态变为 complete
   - 验证菜单栏图标闪烁 3 次
   - 验证图标颜色变为绿色

3. **自动重置**：
   - 等待 3 秒
   - 验证视觉提示自动消失
   - 验证图标恢复到正常大小

4. **减少动画设置**：
   - 在系统设置中启用"减少动画"
   - 重新运行应用
   - 验证闪烁动画被禁用
   - 验证仍显示颜色变化和徽章

## Next Steps

Wave 3 将添加完整的辅助功能支持（VoiceOver、深色/浅色模式适配）。

---

*Completed: 2026-04-02*