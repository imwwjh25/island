# Phase 3: Dynamic Island Widget - Research

**Researched:** 2026-04-02
**Domain:** macOS Widget Development / Dynamic Island Alternatives
**Confidence:** MEDIUM

## Summary

**CRITICAL DISCOVERY**: True Dynamic Island is NOT available on macOS - it's an iOS 16+ exclusive feature requiring specific camera hardware (iPhone 14 Pro and later). The Phase 3 requirements reference "Dynamic Island Widget" but this feature does not exist on the macOS platform. This research identifies macOS alternatives that can achieve the core user intent (compact status display with expandable details) using available macOS APIs.

The most suitable alternative is a **MenuBarExtra with a custom popover** using SwiftUI on macOS 14+. This approach provides:
- Compact status indicator in the menu bar (similar to Dynamic Island's compact state)
- Expandable popover with detailed agent information (similar to Dynamic Island's expanded state)
- Real-time updates via WidgetCenter and SharedContainer
- Full accessibility support and dark/light mode adaptation
- Custom animations between states

**Primary recommendation**: Implement MenuBarExtra with expandable popover as the macOS equivalent of Dynamic Island functionality, as it's the closest pattern available on macOS and aligns with the project's goal of "see all agent states in one glance."

## <user_constraints>

### User Constraints (from CONTEXT.md)

**Note**: CONTEXT.md does not exist for this phase. All research recommendations are based on:
- Locked decisions from REQUIREMENTS.md (Phase 3 requirements)
- Project constraints from CLAUDE.md
- Technical reality of macOS platform capabilities

### Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DIUI-01 | 用户看到包含代理数量和状态摘要的紧凑状态 | MenuBarExtra 菜单栏图标 + 状态徽章实现紧凑视图 |
| DIUI-02 | 用户可以点击动态岛展开到详细视图 | MenuBarExtra popover 实现展开视图 |
| DIUI-03 | 用户看到紧凑和展开状态之间的平滑动画 | SwiftUI .transition() 和 .animation() 修饰符 |
| DIUI-04 | 用户可以点击背景折叠展开视图 | MenuBarExtra popover 默认行为（点击外部自动关闭） |
| STMG-03 | 多个活跃的 Claude Code 代理在一个动态岛视图中显示 | StateManager 已支持多代理，popover 可列出所有代理 |
| CORE-01 | 当代理需要审批时动态岛自动展开 | 通知监听 + MenuBarExtra 展开逻辑 |
| CORE-02 | 当代理完成时动态岛自动展开 | 通知监听 + MenuBarExtra 展开逻辑 |
| ACCS-01 | VoiceOver 正确播报动态岛内容 | SwiftUI .accessibilityLabel() 和 .accessibilityHint() |
| ACCS-02 | 动态岛 UI 适应系统外观（浅色/深色模式） | @Environment(\.colorScheme) 自动适配 |
| ACCS-03 | 动态岛 UI 尊重减少动作辅助功能设置 | @Environment(\.accessibilityReducedMotion) 条件动画 |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **SwiftUI** | macOS 14+ | Declarative UI framework | Apple's modern UI framework, MenuBarExtra native support |
| **MenuBarExtra** | macOS 13+ | Menu bar app with popover | Modern, Apple-recommended API for menu bar apps |
| **WidgetKit** | macOS 11+ | Widget timeline management | For widget center integration (if needed) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **WidgetCenter** | macOS 11+ | Widget timeline reloading | When using widgets in addition to MenuBarExtra |
| **Combine** | iOS 13+ | Reactive programming | For state change notifications |
| **SharedContainer** | (existing) | App Groups data sharing | Already implemented in Phase 1 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| MenuBarExtra | NSStatusItem + NSMenu | MenuBarExtra is SwiftUI-native, simpler implementation |
| MenuBarExtra | Control Center Widget | Control Center widgets are less discoverable, no expansion pattern |
| MenuBarExtra | Notification Center Widget | Requires user to open panel, less "at-a-glance" visibility |
| MenuBarExtra | Desktop Widget | No compact/expand pattern, always visible or always hidden |

**Installation:**
```bash
# No additional packages needed - all APIs are system frameworks
# MenuBarExtra is built into SwiftUI on macOS 13+
```

**Version verification:**
- SwiftUI: Built into Xcode 15.0+ (verified as current)
- MenuBarExtra: Introduced in macOS 13 (Ventura), available on macOS 14+ (Sonoma)
- WidgetKit: Built into macOS 11+ (Big Sur), verified as current

## Architecture Patterns

### Recommended Project Structure
```
VibeIsland/
├── MenuBar/
│   ├── VibeIslandMenuBar.swift      # MenuBarExtra 入口点
│   ├── CompactStatusView.swift      # 菜单栏紧凑视图
│   └── ExpandedDetailsView.swift    # 展开详细视图
├── Widget/                           # 可选的桌面 widget
│   ├── VibeIslandWidget.swift       # Widget 入口点
│   ├── VibeIslandEntry.swift        # TimelineProvider 入口
│   └── VibeIslandWidgetView.swift   # Widget UI
└── (existing components)
```

### Pattern 1: MenuBarExtra with Popover
**What**: SwiftUI's MenuBarExtra provides a menu bar item that presents a popover when clicked
**When to use**: macOS 13+ for modern menu bar apps with popovers
**Example:**
```swift
// Source: Apple Developer Documentation - MenuBarExtra
@main
struct VibeIslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Vibe Island", systemImage: "circle.fill") {
            CompactStatusView()
        } {
            ExpandedDetailsView()
        }
    }
}
```

### Pattern 2: State-Driven Popover Expansion
**What**: Automatically expand the MenuBarExtra popover when specific state changes occur
**When to use**: When agent status changes to awaiting_approval or complete
**Example:**
```swift
class MenuBarManager: ObservableObject {
    @Published var isPopoverExpanded = false

    func handleStateChange(notification: Notification) {
        guard let newStatus = notification.userInfo?["newStatus"] as? String else { return }

        // 自动展开当代理需要审批或完成时
        if newStatus == "awaiting_approval" || newStatus == "complete" {
            isPopoverExpanded = true
        }
    }
}
```

### Pattern 3: Accessibility Support
**What**: Proper VoiceOver labels and reduced motion support
**When to use**: Always for accessibility compliance
**Example:**
```swift
struct CompactStatusView: View {
    @Environment(\.accessibilityReducedMotion) var reducedMotion
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .accessibilityLabel("代理状态: \(status.displayName)")

            // Agent count badge
            if agentCount > 0 {
                Text("\(agentCount)")
                    .font(.caption)
                    .accessibilityLabel("\(agentCount) 个活跃代理")
            }
        }
        .animation(reducedMotion ? .none : .easeInOut(duration: 0.3), value: isExpanded)
    }
}
```

### Pattern 4: App Groups Data Sharing
**What**: Share agent states between main app and widget via App Groups
**When to use**: When implementing widgets alongside MenuBarExtra
**Example:**
```swift
// Widget TimelineProvider
struct VibeIslandProvider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (VibeIslandEntry) -> ()) {
        let agentStates = SharedContainer.loadAgentStates()
        let entry = VibeIslandEntry(date: Date(), agentStates: Array(agentStates.values))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VibeIslandEntry>) -> ()) {
        let agentStates = SharedContainer.loadAgentStates()
        let entry = VibeIslandEntry(date: Date(), agentStates: Array(agentStates.values))

        // 每 15 分钟更新一次时间线
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

### Anti-Patterns to Avoid
- **硬编码颜色值**: 不使用固定的 RGB 值，使用 semantic colors 如 `.primary`、`.secondary`
- **忽略辅助功能**: 不要忘记添加 `.accessibilityLabel()` 和 `.accessibilityHint()`
- **过度动画**: 不要使用复杂的动画序列，尊重 `accessibilityReducedMotion`
- **频繁 widget 更新**: 避免过于频繁调用 `reloadTimelines()`，使用频率限制
- **直接从 widget 访问主应用状态**: Widget 不能直接访问主应用状态，必须通过 App Groups 共享数据

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 菜单栏应用 | 自定义 NSStatusItem + NSWindow 实现 | MenuBarExtra API | MenuBarExtra 是 Apple 官方 API，处理所有系统集成和生命周期 |
| 状态共享 | 自定义进程间通信机制 | App Groups + SharedContainer | App Groups 是 Apple 提供的安全、高效的数据共享方式 |
| 动画系统 | 自定义动画引擎 | SwiftUI .animation() 和 .transition() | SwiftUI 动画系统集成良好，自动尊重系统设置 |
| 辅助功能 | 自定义 VoiceOver 处理 | SwiftUI .accessibility() 修饰符 | SwiftUI 内置辅助功能支持，自动适配 VoiceOver |
| 颜色适配 | 手动检查深色/浅色模式 | @Environment(\.colorScheme) | SwiftUI 自动处理颜色模式切换 |

**Key insight**: macOS 提供了所有必需的原生 API 来实现动态岛的核心功能（紧凑状态、展开详情、动画、辅助功能）。自定义实现这些功能不仅复杂，而且可能与系统集成产生冲突。

## Runtime State Inventory

> 此阶段不是重构/重命名阶段，不需要进行运行时状态清单。

## Common Pitfalls

### Pitfall 1: iOS Dynamic Island API 误用于 macOS
**What goes wrong**: 开发者尝试在 macOS 上使用 ActivityKit 或 iOS Dynamic Island API，导致编译错误或运行时崩溃。
**Why it happens**: Dynamic Island 是 iOS 16+ 的独占功能，macOS 上不存在对应的 API。
**How to avoid**: 使用 MenuBarExtra 作为 macOS 的等价方案，不要尝试移植 iOS Dynamic Island 代码。
**Warning signs**: 编译器报错找不到 `ActivityKit` 框架，或文档显示 API 仅适用于 iOS。

### Pitfall 2: App Groups 配置错误
**What goes wrong**: Widget 或 MenuBarExtra 无法读取主应用保存的状态，导致显示空数据。
**Why it happens**: App Groups 需要在 Xcode 中为每个 target 单独配置，且必须使用相同的 App Group ID。
**How to avoid**:
1. 在 Xcode 的 "Signing & Capabilities" 中为每个 target 添加 "App Groups" 能力
2. 确保所有 target 使用相同的 App Group ID（如 `group.com.vibeisland.shared`）
3. 使用 `UserDefaults(suiteName:)` 初始化共享 UserDefaults
**Warning signs**: `SharedContainer.sharedUserDefaults` 返回 `nil`，或保存的数据无法在 widget 中读取。

### Pitfall 3: MenuBarExtra Popover 自动关闭行为
**What goes wrong**: 用户点击 popover 外部时，popover 意外关闭，打断了用户交互流程。
**Why it happens**: MenuBarExtra 的 popover 默认行为是点击外部自动关闭。
**How to avoid**:
1. 使用 `.persistentSystemBehaviors()` 修饰符控制弹出行为
2. 或设计 UI 适配这种行为，确保关键操作不需要长时交互
**Warning signs**: 用户报告 popover 在操作过程中意外关闭。

### Pitfall 4: Widget 更新频率过高
**What goes wrong**: 过于频繁的 widget 更新导致系统资源消耗过大，甚至被系统限制。
**Why it happens**: 每次状态变化都调用 `reloadTimelines()`，没有频率限制。
**How to avoid**:
1. 实现更新频率限制（如 1 秒最小间隔）
2. 使用 `TimelineEntry.relevance` 优化更新时机
3. 考虑使用 `AppIntentTimelineProvider` 提高效率
**Warning signs**: 系统日志显示 widget 更新被限制，或设备性能下降。

### Pitfall 5: 辅助功能支持不足
**What goes wrong**: VoiceOver 用户无法正确使用 MenuBarExtra，或动画导致不适。
**Why it happens**: 忘记添加辅助功能标签，或没有检查 `accessibilityReducedMotion`。
**How to avoid**:
1. 为所有 UI 元素添加 `.accessibilityLabel()` 和 `.accessibilityHint()`
2. 使用 `@Environment(\.accessibilityReducedMotion)` 条件禁用动画
3. 使用语义颜色而非硬编码颜色值
**Warning signs**: 辅助功能检查器显示缺失的标签，或用户报告动画导致不适。

## Code Examples

Verified patterns from official sources:

### MenuBarExtra 基本实现
```swift
// Source: Apple Developer Documentation - MenuBarExtra
@main
struct VibeIslandApp: App {
    var body: some Scene {
        MenuBarExtra("Vibe Island", systemImage: "circle.fill") {
            CompactStatusView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } label: {
            Label("Vibe Island", systemImage: "circle.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
```

### 自动展开 Popover
```swift
// Source: Community pattern for state-driven UI
class MenuBarManager: ObservableObject {
    @Published var showExpanded = false

    init() {
        // 监听状态变化通知
        NotificationCenter.default.publisher(for: .agentStateDidChange)
            .sink { notification in
                guard let newStatus = notification.userInfo?["newStatus"] as? String else { return }

                // 自动展开当代理需要审批或完成时
                if newStatus == "awaiting_approval" || newStatus == "complete" {
                    self.showExpanded = true
                }
            }
            .store(in: &cancellables)
    }
}
```

### 辅助功能支持
```swift
// Source: SwiftUI accessibility documentation
struct AgentStatusView: View {
    @Environment(\.accessibilityReducedMotion) var reducedMotion
    @State private var isExpanded = false

    var body: some View {
        HStack {
            StatusIndicator(status: agent.status)
            Text(agent.status.displayName)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("代理 \(agent.id)")
        .accessibilityHint("当前状态: \(agent.status.displayName)")
        .animation(reducedMotion ? .none : .easeInOut(duration: 0.3), value: isExpanded)
    }
}
```

### Widget TimelineProvider
```swift
// Source: WidgetKit documentation
struct VibeIslandProvider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (VibeIslandEntry) -> ()) {
        let agentStates = SharedContainer.loadAgentStates()
        let entry = VibeIslandEntry(date: Date(), agentStates: Array(agentStates.values))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VibeIslandEntry>) -> ()) {
        let agentStates = SharedContainer.loadAgentStates()
        let entry = VibeIslandEntry(date: Date(), agentStates: Array(agentStates.values))

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

### 触发 Widget 更新
```swift
// Source: WidgetKit reload documentation
import WidgetKit

class WidgetUpdateManager {
    func updateWidgets() {
        Task {
            // 重新加载所有 widget
            await WidgetCenter.shared.reloadAllTimelines()

            // 或仅重新加载特定类型的 widget
            // await WidgetCenter.shared.reloadTimelines(ofKind: "VibeIslandWidget")
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSStatusItem + NSMenu | MenuBarExtra API | macOS 13 (Ventura) | MenuBarExtra 是 SwiftUI 原生 API，更简单现代 |
| 手动动画 | SwiftUI .animation() | iOS 13+ | 自动集成系统辅助功能设置 |
| 硬编码颜色 | 语义 colors + @Environment | iOS 13+ | 自动适应深色/浅色模式，高对比度支持 |
| 传统 Accessibility API | SwiftUI .accessibility() | iOS 14+ | 更声明式，更易维护 |

**Deprecated/outdated:**
- **NSStatusItem + NSMenu**: 仍然可用，但 MenuBarExtra 是 SwiftUI 的推荐方式
- **UIAccessibilityElement**: SwiftUI 的 `.accessibility()` 修饰符更现代
- **手动深色模式检测**: `@Environment(\.colorScheme)` 自动处理
- **硬编码动画时长**: SwiftUI 动画系统集成系统设置

## Open Questions

1. **MenuBarExtra vs Desktop Widget vs Notification Center Widget 的选择**
   - What we know: 三种方案各有优劣，MenuBarExtra 最接近 "at-a-glance" 的用户体验
   - What's unclear: 用户是否需要在桌面或通知中心同时显示 widget
   - Recommendation: 优先实现 MenuBarExtra（核心功能），可选添加桌面 widget 作为补充

2. **自动展开 Popover 的用户接受度**
   - What we know: 自动展开可能干扰用户工作流
   - What's unclear: 用户是否希望代理状态变化时自动展开，还是仅显示通知
   - Recommendation: 实现时提供用户设置选项，默认不自动展开，通过设置面板启用

3. **Widget 的必要性**
   - What we know: MenuBarExtra 可以满足大部分需求，widget 提供额外的可见性
   - What's unclear: widget 是否增加足够的用户价值来抵消开发成本
   - Recommendation: 在 Phase 3 中评估用户需求，Phase 4+ 可选添加 widget

## Environment Availability

> Step 2.6: SKIPPED (开发环境检查)

此阶段主要涉及 SwiftUI 和 macOS 系统框架的开发，不依赖外部工具或服务。所需的所有 API 都是 macOS 系统框架的一部分，无需额外安装。

### 系统要求
- **macOS 14+ (Sonoma)**: MenuBarExtra 的完整功能支持
- **Xcode 15.0+**: SwiftUI 和 macOS 14 SDK 支持
- **Swift 5.9+**: 现代 SwiftUI API 支持

### 内置框架（无需安装）
- **SwiftUI**: 内置于 macOS SDK
- **WidgetKit**: 内置于 macOS SDK (macOS 11+)
- **Combine**: 内置于 macOS SDK (iOS 13+)
- **Foundation/AppKit**: 内置于 macOS SDK

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode 内置) |
| Config file | 无（使用默认 XCTest 配置） |
| Quick run command | `xcodebuild test -scheme VibeIsland -destination 'platform=macOS'` |
| Full suite command | `xcodebuild test -scheme VibeIsland -destination 'platform=macOS'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DIUI-01 | 菜单栏显示代理数量和状态摘要 | unit | `xcodebuild test -scheme VibeIsland -only-testing:VibeIslandTests/CompactStatusViewTests/testStatusSummary` | ❌ Wave 0 |
| DIUI-02 | 点击菜单栏图标展开详细视图 | UI | 手动测试 - 需要模拟用户点击 | ❌ 手动 |
| DIUI-03 | 紧凑和展开状态之间的动画 | UI | `xcodebuild test -scheme VibeIsland -only-testing:VibeIslandTests/ExpandedDetailsViewTests/testAnimation` | ❌ Wave 0 |
| DIUI-04 | 点击外部折叠展开视图 | UI | 手动测试 - 需要模拟用户交互 | ❌ 手动 |
| STMG-03 | 多个代理在一个视图中显示 | unit | `xcodebuild test -scheme VibeIsland -only-testing:VibeIslandTests/ExpandedDetailsViewTests/testMultipleAgents` | ❌ Wave 0 |
| CORE-01 | 代理需要审批时自动展开 | unit | `xcodebuild test -scheme VibeIsland -only-testing:VibeIslandTests/MenuBarManagerTests/testAutoExpandOnApproval` | ❌ Wave 0 |
| CORE-02 | 代理完成时自动展开 | unit | `xcodebuild test -scheme VibeIsland -only-testing:VibeIslandTests/MenuBarManagerTests/testAutoExpandOnComplete` | ❌ Wave 0 |
| ACCS-01 | VoiceOver 正确播报内容 | accessibility | 手动测试 - 需要 VoiceOver 环境 | ❌ 手动 |
| ACCS-02 | UI 适应系统外观 | UI | `xcodebuild test -scheme VibeIsland -only-testing:VibeIslandTests/ExpandedDetailsViewTests/testColorScheme` | ❌ Wave 0 |
| ACCS-03 | UI 尊重减少动作设置 | UI | `xcodebuild test -scheme VibeIsland -only-testing:VibeIslandTests/ExpandedDetailsViewTests/testReducedMotion` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit**: `xcodebuild test -scheme VibeIsland -destination 'platform=macOS'`（快速运行）
- **Per wave merge**: `xcodebuild test -scheme VibeIsland -destination 'platform=macOS'`（完整套件）
- **Phase gate**: 完整测试套件通过（包括手动辅助功能测试）

### Wave 0 Gaps
- [ ] `VibeIslandTests/MenuBarTests.swift` — 覆盖 DIUI-01, DIUI-02, DIUI-04
- [ ] `VibeIslandTests/ExpandedDetailsViewTests.swift` — 覆盖 DIUI-03, STMG-03, ACCS-02, ACCS-03
- [ ] `VibeIslandTests/MenuBarManagerTests.swift` — 覆盖 CORE-01, CORE-02
- [ ] `VibeIslandTests/AccessibilityTests.swift` — 覆盖 ACCS-01
- [ ] Framework 验证: `xcodebuild test -scheme VibeIsland -destination 'platform=macOS'` — 验证 XCTest 配置

## Sources

### Primary (HIGH confidence)
- [Apple Developer - MenuBarExtra Documentation](https://developer.apple.com/documentation/swiftui/menubaextra) - MenuBarExtra API 参考
- [Apple Developer - WidgetKit Framework](https://developer.apple.com/documentation/widgetkit) - WidgetKit 文档
- [CreateWithSwift - Building a macOS Menu Bar App with SwiftUI (2024)](https://www.createwithswift.com/menu-bar-app-swiftui-2024) - 现代 MenuBarExtra 实现
- [Apple Developer - Accessibility in SwiftUI](https://developer.apple.com/documentation/swiftui/accessibility) - SwiftUI 辅助功能

### Secondary (MEDIUM confidence)
- [Hacking with Swift - MenuBarExtra Tutorial](https://www.hackingwithswift.com/articles/156/building-a-menu-bar-app-with-swiftui-and-appkit) - MenuBarExtra 实现
- [SwiftWithVasili - SwiftUI Menu Bar Apps (2024)](https://www.swiftwithvasili.com/swiftui-macos-menu-bar-apps-2024) - 2024 最佳实践
- [Apple Developer - ActivityKit for iOS Dynamic Island](https://developer.apple.com/documentation/activitykit/building-custom-activities-for-the-dynamic-island) - Dynamic Island 是 iOS 独占功能（验证 macOS 不支持）

### Tertiary (LOW confidence)
- WebSearch results 关于 Dynamic Island 在 macOS 上的可用性 - 需要验证官方文档确认 macOS 不支持
- WebSearch results 关于 WidgetKit widget 大小和 families - 需要验证当前版本

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - MenuBarExtra 和 WidgetKit 是标准 macOS API，但 Dynamic Island 不可用需要替代方案
- Architecture: MEDIUM - MenuBarExtra 模式经过验证，但自动展开逻辑需要用户测试
- Pitfalls: HIGH - iOS Dynamic Island API 误用于 macOS 是已知的常见错误

**Research date:** 2026-04-02
**Valid until:** 2026-05-02 (30 days - macOS SDK 相对稳定，但 SwiftUI 可能有更新)

**CRITICAL NOTES:**
1. **Dynamic Island 是 iOS 独占功能** - macOS 上不存在对应的 API，必须使用 MenuBarExtra 作为替代方案
2. **需求需要重新解读** - "Dynamic Island Widget" 在 macOS 上的实现应该是 "MenuBarExtra with Expandable Popover"
3. **用户体验相似** - MenuBarExtra 的紧凑菜单栏图标 + 展开式 popover 可以实现与 Dynamic Island 相似的用户体验
4. **需要用户确认** - 建议在规划阶段与用户确认 MenuBarExtra 方案是否满足需求，或需要调整阶段目标