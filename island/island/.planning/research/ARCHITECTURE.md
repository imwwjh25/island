# Architecture Patterns

**Domain:** macOS menu bar dynamic status indicator
**Researched:** 2026-04-03

---

## Recommended Architecture

### 整体结构

```
┌─────────────────────────────────────────────────────────────┐
│                     VibeIslandMenuBar                        │
│                   (@main App 入口)                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     MenuBarManager                           │
│           (状态变化协调 + Widget 更新触发)                    │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │SocketMonitor│  │WindowMonitor│  │DynamicIconGenerator │  │
│  │  (socket)   │  │ (accessibility)│   (新增 - NSImage)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│          │              │                    │               │
│          ▼              ▼                    ▼               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    StateManager                       │    │
│  │         (中央状态存储 + NotificationCenter)          │    │
│  │                                                      │    │
│  │  agentStates: [AgentState]  ← 所有组件写入此状态      │    │
│  │  @Published → 自动触发 UI 更新                        │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     MenuBarExtra                             │
│                                                              │
│  image: dynamicIcon ← DynamicIconGenerator.create()         │
│                                                              │
│  ┌─────────────┐                        ┌─────────────────┐ │
│  │ 紧凑视图    │ ← statusCounts         │ 展开视图         │ │
│  │ (状态圆点)  │                        │ (代理列表)       │ │
│  └─────────────┘                        └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **MenuBarManager** | 协调所有监控器，触发 UI/Widget 更新 | 所有子组件、StateManager |
| **SocketMonitor** | 接收 socket 消息，解析 JSON | StateManager (写入状态) |
| **WindowMonitor** | 监控终端窗口标题，解析状态 | StateManager (写入状态) |
| **ProcessMonitor** | 检测 Claude 进程 PID | StateManager (写入状态) |
| **DynamicIconGenerator** (新增) | 根据状态生成动态图标 | StateManager (读取状态) |
| **StateManager** | 中央状态存储，发布通知 | 所有组件 |
| **SoundManager** | 播放状态变化音效 | MenuBarManager (触发) |
| **TerminalController** | 跳转到终端标签页 | ExpandedDetailsView (用户触发) |

---

## Data Flow

### 状态检测流程

```
Claude Code Agent → Socket/窗口标题/进程检测
                         │
                         ▼
                    StateManager.updateAgentState()
                         │
                         ▼
                    NotificationCenter.post(.agentStateDidChange)
                         │
                         ├→ MenuBarManager.handleStateChange()
                         │      │
                         │      ├→ SoundManager.playStateChangeSound()
                         │      ├→ WidgetCenter.reloadAllTimelines()
                         │      └→ DynamicIconGenerator.updateIcon()
                         │
                         └→ CompactStatusView (自动更新 @Published)
                         └→ ExpandedDetailsView (自动更新 @Published)
```

### 图标生成流程

```
StateManager.agentStates 变化
         │
         ▼
DynamicIconGenerator.createIcon(statusCounts)
         │
         ├→ 计算各状态类型的数量
         ├→ 创建 NSImage(size: 22x18)
         ├→ lockFocus → 绘制圆点/徽章 → unlockFocus
         └→ 设置 .template 渲染模式
         │
         ▼
MenuBarExtra(image: dynamicIcon) 更新显示
```

---

## Patterns to Follow

### Pattern 1: NSImage Template Rendering

**What:** 使用模板图像模式，让 macOS 自动适配 light/dark mode

**When:** 所有菜单栏图标生成

**Example:**
```swift
func createTemplateIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 22, height: 18))
    image.lockFocus()
    // 绘制内容...
    image.unlockFocus()
    return image.withRenderingMode(.alwaysTemplate)  // 关键
}
```

### Pattern 2: State Aggregation Before Icon Generation

**What:** 先聚合状态统计，再生成图标，避免每次状态变化都重绘

**When:** DynamicIconGenerator 获取状态时

**Example:**
```swift
struct StatusCounts {
    let inProgress: Int
    let complete: Int
    let awaitingApproval: Int
    let total: Int
}

func getStatusCounts(from states: [AgentState]) -> StatusCounts {
    StatusCounts(
        inProgress: states.filter { $0.status == .inProgress }.count,
        complete: states.filter { $0.status == .complete }.count,
        awaitingApproval: states.filter { $0.status == .awaitingApproval }.count,
        total: states.count
    )
}
```

### Pattern 3: Complementary Detection Mechanisms

**What:** 多检测机制互补，提高状态识别准确率

**When:** WindowMonitor 检测终端状态

**Example:**
```swift
// 主机制：AXUIElement 窗口标题
let axTitles = getTitlesViaAXUIElement(app)

// 补充机制：CGWindowList 窗口列表
let cgTitles = getTitlesViaCGWindowList()

// 合并结果
let allTitles = axTitles + cgTitles.filter { !axTitles.contains($0) }
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: 在 SwiftUI View 中直接绘制图标

**What:** 在 View body 中使用 GeometryReader 或 Canvas 绘制

**Why bad:** 每次渲染都重新绘制，性能差；无法直接用于 MenuBarExtra image 参数

**Instead:** 创建独立的 DynamicIconGenerator 类，生成 NSImage

### Anti-Pattern 2: 高频图标更新

**What:** 每个状态变化都立即更新图标

**Why bad:** 菜单栏图标更新有延迟，高频更新会导致闪烁卡顿

**Instead:** 使用频率限制（如 0.5 秒最小间隔），或批量更新

### Anti-Pattern 3: 状态同步过度依赖 NotificationCenter

**What:** 所有状态变化都通过 NotificationCenter 广播

**Why bad:** 现有实现已过度使用，可能导致性能问题

**Instead:** 对于高频更新（如图标），直接观察 StateManager.@Published 属性

---

## Scalability Considerations

| Concern | At 1-5 agents | At 10-20 agents | At 50+ agents |
|---------|---------------|-----------------|---------------|
| 图标尺寸 | 22x18 足够 | 可能需要加宽 | 滚动显示或数字摘要 |
| 状态更新频率 | 无问题 | 可能需要频率限制 | 必须批量更新 |
| 窗口标题解析 | 无问题 | 可能需要优化正则 | 需要缓存机制 |
| Socket 消息处理 | 无问题 | 无问题 | 需要队列缓冲 |

---

## Integration with Existing Code

### 新增组件位置

```
VibeIsland/
├── MenuBar/
│   ├── VibeIslandMenuBar.swift    ← 修改：动态图标参数
│   ├── CompactStatusView.swift     ← 保持：展开视图中的圆点
│   └── ExpandedDetailsView.swift   ← 保持
│   └── DynamicIconGenerator.swift  ← 新增
│
├── Window/
│   ├── WindowMonitor.swift         ← 扩展：CGWindowList 补充
│   └── CGWindowListHelper.swift    ← 新增（可选）
│
├── State/
│   ├── StateManager.swift          ← 扩展：状态聚合方法
│   └── StatusCounts.swift          ← 新增
```

---

## Sources

- 现有代码架构分析 (HIGH)
- Apple NSImage/AppKit 文档 (HIGH)
- macOS 菜单栏应用模式 (MEDIUM)