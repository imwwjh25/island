---
phase: 3
slug: dynamic-island-widget
status: draft
shadcn_initialized: false
preset: none
created: 2026-04-02
---

# Phase 3 — UI Design Contract

> Visual and interaction contract for Phase 3 (MenuBarExtra Widget) - macOS MenuBarExtra + SwiftUI
>
> **重要发现**: macOS 没有 iOS 风格的 Dynamic Island（需要特定相机硬件的 iOS 16+ 专用功能）。本设计使用 MenuBarExtra + Popover 作为 macOS 等效方案，提供类似的紧凑状态显示和可展开详细视图体验。

---

## Design System

| Property | Value |
|----------|-------|
| Tool | MenuBarExtra (macOS 14+) + SwiftUI |
| Preset | Apple MenuBarExtra native |
| Component library | SwiftUI native views |
| Icon library | SF Symbols (Apple) |
| Font | System font (SF Pro / SF Text) |

---

## Spacing Scale

MenuBarExtra Popover 使用标准 4pt 网格系统：

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | 最小内边距、图标间距 |
| sm | 8pt | 紧凑元素间距 |
| md | 16pt | 默认元素间距 |
| lg | 24pt | 区域分隔 |
| xl | 32pt | 展开视图边距 |

**例外**:
- 菜单栏图标区域由系统控制（固定高度 ~22pt）
- Popover 最小高度 ~100pt
- Popover 最大高度 ~400pt（超出滚动）

---

## Typography

使用 SwiftUI 系统字体，自动适配系统设置：

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 13pt | Regular | 1.4 |
| Label | 11pt | Regular | 1.3 |
| Heading | 15pt | Semibold | 1.2 |
| Display | 17pt | Semibold | 1.2 |

**字体族**: `.systemFont(ofSize: ...)` 或 `.font(.body)`, `.font(.headline)`

**字重**: 仅使用 Regular 和 Semibold 两种

---

## Color

使用系统语义颜色，自动适配深色/浅色模式：

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `.primary` | 代理名称、标题 "Vibe Island"、主要文本 |
| Secondary (30%) | `.secondary` | 描述/子状态文本、次要信息 |
| Accent (10%) | `.blue` / `.green` / `.orange` | 状态指示 |
| Destructive | `.red` | 错误状态（如有） |

**状态颜色映射**:
- **in_progress**: `.blue` (蓝色)
- **complete**: `.green` (绿色)
- **awaiting_approval**: `.orange` (橙色)
- **idle**: `.gray` (灰色)

**Accent 保留用于**:
- 代理状态圆点（in_progress 用蓝色圆点，complete 用绿色圆点，awaiting_approval 用橙色圆点）
- "等待审批" 状态标签文本
- "完成" 状态标签文本

---

## Copywriting Contract

所有文本使用中文（项目规范）：

| Element | Copy |
|---------|------|
| 紧凑视图 | "{N} 个代理" 或 "{N} agents" |
| 空状态 | "无活跃代理" |
| 状态标签 | "进行中" / "完成" / "等待审批" |
| VoiceOver 前缀 | "Vibe Island 动态岛，" |

---

## View Specifications

### MenuBarIcon（菜单栏图标）

```
┌──────────┐
│ [●●●] 3  │
│ [状态圆点][徽章数]
└──────────┘
```

**布局**:
- 图标: SF Symbols 系统图标
- 徽章: 状态圆点（2-3 个彩色圆点表示活跃代理）+ 数字徽章显示代理数量
- 大小: 标准菜单栏图标（22pt 高度）

### PopoverView（展开视图）

```
┌────────────────────────────────────────────┐
│  Vibe Island                        [关闭X] │
├────────────────────────────────────────────┤
│                                            │
│  [●] 代理 1                      [进行中]   │
│  └─ 描述/子状态（可选）                     │
│                                            │
│  [●] 代理 2                      [完成]     │
│  └─ 描述/子状态（可选）                     │
│                                            │
│  [●] 代理 3                    [等待审批]   │
│                                            │
└────────────────────────────────────────────┘
```

**布局**:
- 标题栏: "Vibe Island" + 关闭按钮
- 列表项: 水平布局（状态圆点 + 代理名称 + 状态标签）
- 主焦点: 代理列表（核心内容区域）
- Bottom: 可选的页脚信息（如总代理数统计）

---

## Interaction Patterns

### 展开/折叠

| 动作 | 行为 | 动画 |
|------|------|------|
| 点击紧凑视图 | 展开到详细视图 | 0.3s ease-in-out |
| 点击背景区域 | 折叠到紧凑视图 | 0.3s ease-in-out |
| 自动展开（需要审批） | 立即展开到详细视图 | 0.2s ease-out |
| 自动展开（完成） | 立即展开到详细视图 | 0.2s ease-out |

### 辅助功能

| 设置 | 行为 |
|------|------|
| VoiceOver 启用 | 完整朗读动态岛内容 |
| 减少动画 | 禁用展开/折叠动画或简化 |
| 高对比度 | 使用高对比度颜色方案 |

---

## Registry Safety

不使用外部组件库。仅使用 SwiftUI 原生组件和 WidgetKit API。

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| SwiftUI native | View, Text, Image, Color, HStack, VStack | 不需要 |

**注意**: WidgetKit 有严格的 API 限制，必须遵守 Apple 的 Dynamic Island 设计指南。

---

## Animation Contract

### 标准过渡动画

```swift
.animation(.easeInOut(duration: 0.3), value: isExpanded)
```

### 减少动画模式

```swift
.animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: isExpanded)
```

### 自动展开动画

```swift
.animation(.easeOut(duration: 0.2), value: shouldExpand)
```

---

## Accessibility Contract

### VoiceOver

每个视图元素必须有 `.accessibilityLabel`:

| 元素 | VoiceOver 文本 |
|------|----------------|
| 紧凑视图 | "Vibe Island 动态岛，{N} 个代理活跃" |
| 代理卡片 | "代理 {ID}，状态 {状态}" |
| 状态标签 | "状态，{状态}" |

### 辅助功能修饰符

```swift
.accessibilityLabel("代理 \(agentId)，状态 \(status)")
.accessibilityHint("点击查看详情")
.accessibilityAddTraits(.isButton)
```

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS - 中文文本，简洁准确
- [x] Dimension 2 Visuals: PASS - 遵循 Apple MenuBarExtra 设计规范，主焦点明确（代理列表）
- [x] Dimension 3 Color: PASS - 使用系统语义颜色，Dominant/Secondary 用途明确
- [x] Dimension 4 Typography: PASS - 使用系统字体，2 种字重（Regular, Semibold）
- [x] Dimension 5 Spacing: PASS - 所有间距为 4 的倍数（4, 8, 16, 24, 32）
- [x] Dimension 6 Registry Safety: PASS - 仅使用 SwiftUI 原生组件

**Approval:** approved 2026-04-02

---

*UI-SPEC created: 2026-04-02*