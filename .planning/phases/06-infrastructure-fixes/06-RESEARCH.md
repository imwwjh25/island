# Phase 6: Infrastructure Fixes - Research

**Researched:** 2026-04-03
**Domain:** macOS SwiftUI Singleton State, AVAudioSession, Accessibility Permissions
**Confidence:** HIGH

## Summary

Phase 6 修复三个关键基础设施问题，确保后续功能正常工作：

1. **FIX-01 (状态丢失):** SwiftUI 视图中使用 `@ObservedObject` 与单例组合会导致视图更新时状态丢失。正确模式应为 `@StateObject` 或直接静态访问。
2. **FIX-02 (音效失效):** macOS 菜单栏应用 (LSUIElement) 需要 `AVAudioApplication` 配置，而非 iOS 的 `AVAudioSession`。需要正确设置 category 并激活应用。
3. **FIX-03 (Accessibility 权限):** 当前实现仅打印警告，未提供用户引导。需要添加权限请求流程、拒绝时的 UI 提示，以及权限状态监控。

**Primary recommendation:** 修复顺序为 FIX-01 -> FIX-03 -> FIX-02，因为状态管理是所有功能的基础。

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIX-01 | 修复 @ObservedObject 与单例组合导致的状态丢失问题 | SwiftUI 单例模式最佳实践：@StateObject vs @ObservedObject |
| FIX-02 | 配置 AVAudioSession 使音效在菜单栏应用中正常工作 | macOS AVAudioApplication API，LSUIElement 应用音频配置 |
| FIX-03 | 添加 Accessibility 权限检查并提示用户授权 | AXIsProcessTrustedWithOptions API，DistributedNotificationCenter 监控 |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 14+ | UI 框架 | 声明式 UI，原生支持 |
| Combine | Latest | 响应式编程 | ObservableObject 发布状态变化 |
| AVFoundation | Latest | 音频播放 | 系统音频框架 |
| Accessibility API | macOS 10.9+ | 权限检查 | AXIsProcessTrustedWithOptions 是官方 API |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AVAudioApplication | macOS 11+ | macOS 音频 category | 代替 iOS 的 AVAudioSession |
| DistributedNotificationCenter | macOS 10.0+ | 权限变化监听 | 监控 Accessibility 权限状态变化 |

## Architecture Patterns

### 当前问题代码分析

**问题 1: CompactStatusView.swift (line 17)**
```swift
// 当前错误模式
@ObservedObject private var stateManager = StateManager.shared
```

**问题 2: ExpandedDetailsView.swift (lines 16-19)**
```swift
// 当前错误模式
@ObservedObject private var stateManager = StateManager.shared
@ObservedObject private var menuBarManager = MenuBarManager.shared
```

**问题 3: VibeIslandMenuBar.swift (line 112)**
```swift
// 当前错误模式
@ObservedObject private var menuBarManager = MenuBarManager.shared
```

**问题根源:**
- `@ObservedObject` 不持有对象生命周期，每次视图重建时会重新创建观察
- 单例已存在，但视图可能丢失对单例的观察连接
- 导致状态更新时视图不响应

### 推荐修复模式

**Pattern 1: @StateObject 用于视图拥有的单例引用**
```swift
// 正确模式 - 视图层级入口
@StateObject private var stateManager = StateManager.shared
```
**何时使用:** App 入口或顶层视图，确保单例观察生命周期与视图绑定。

**Pattern 2: 直接静态访问（无需 Property Wrapper）**
```swift
// 正确模式 - 子视图直接访问
var body: some View {
    Text("\(StateManager.shared.agentStates.count)")
}
```
**何时使用:** 只读访问，无需响应式更新的场景。

**Pattern 3: @EnvironmentObject 依赖注入**
```swift
// App 入口注入
VibeIslandMenuBar: App {
    var body: some Scene {
        MenuBarExtra(...) {
            ExpandedDetailsView()
                .environmentObject(StateManager.shared)
        }
    }
}

// 子视图接收
struct ExpandedDetailsView: View {
    @EnvironmentObject var stateManager: StateManager
}
```
**何时使用:** 需要在多个子视图间共享状态，且希望响应式更新。

### Pattern 4: AVAudioApplication 配置 (macOS)
```swift
// macOS 音频配置
import AVFAudio

class SoundManager {
    func configureAudioSession() {
        // macOS 使用 AVAudioApplication，不是 AVAudioSession
        try? AVAudioApplication.setCategory(.playback, mode: .default)
        
        // 或者使用更详细的配置
        try? AVAudioApplication.setCategory(
            .playback,
            mode: .default,
            policy: .default,
            options: [.mixWithOthers]
        )
    }
    
    func playSound() {
        // 菜单栏应用可能需要先激活
        NSApplication.shared.activate(ignoringOtherApps: true)
        audioPlayer?.play()
    }
}
```

### Pattern 5: Accessibility 权限管理
```swift
import ApplicationServices

class AccessibilityManager: ObservableObject {
    @Published var hasPermission: Bool = false
    @Published var showPermissionPrompt: Bool = false
    
    func checkPermission(promptUser: Bool = false) {
        let options: CFDictionary?
        if promptUser {
            // 显示系统授权对话框
            options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        } else {
            options = nil
        }
        
        hasPermission = AXIsProcessTrustedWithOptions(options)
        
        if !hasPermission && promptUser {
            showPermissionPrompt = true
        }
    }
    
    func startMonitoring() {
        // 监听权限变化
        DistributedNotificationCenter.default().addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hasPermission = AXIsProcessTrusted()
        }
    }
}
```

### Anti-Patterns to Avoid

- **@ObservedObject 初始化单例:** 每次视图重建会重新创建观察连接，可能导致状态丢失
- **使用 AVAudioSession (iOS API) on macOS:** macOS 应使用 `AVAudioApplication`
- **权限拒绝后无 UI 反馈:** 用户不知道为什么功能不工作

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 状态响应式绑定 | 手动 NotificationCenter 观察 | @StateObject / @EnvironmentObject | SwiftUI 内置，更可靠 |
| macOS 音频 category | 自定义音频配置 | AVAudioApplication.setCategory | 系统框架处理后台播放 |
| 权限状态监听 | 定时轮询 AXIsProcessTrusted | DistributedNotificationCenter | 实时响应，无性能开销 |

## Common Pitfalls

### Pitfall 1: @ObservedObject 单例状态丢失

**What goes wrong:** 视图使用 `@ObservedObject var singleton = Singleton.shared`，当视图因其他状态变化重建时，可能丢失对单例的观察连接。

**Why it happens:** 
- `@ObservedObject` 不持有对象生命周期
- SwiftUI 视图是 struct，每次重建是新实例
- 单例存在但观察者可能失效

**How to avoid:**
1. 顶层视图使用 `@StateObject` 持有单例引用
2. 子视图使用 `@EnvironmentObject` 接收注入
3. 或直接使用 `Singleton.shared.property` 访问（无需响应式）

**Warning signs:**
- 状态变化但 UI 不更新
- 单例数据存在但视图显示空或旧值

### Pitfall 2: macOS 菜单栏应用音效不播放

**What goes wrong:** AVAudioPlayer 在 LSUIElement 应用中不播放声音。

**Why it happens:**
- macOS 菜单栏应用不在 Dock 显示，系统可能不激活其音频会话
- 使用 iOS 的 AVAudioSession API 而非 macOS 的 AVAudioApplication
- 未设置正确的 audio category

**How to avoid:**
1. 使用 `AVAudioApplication.setCategory(.playback)` 配置
2. 播放前调用 `NSApplication.shared.activate(ignoringOtherApps: true)`
3. 确保 Info.plist 有正确的音频 entitlement

**Warning signs:**
- audioPlayer.play() 调用成功但无声音
- 只有应用在前台时音效工作

### Pitfall 3: Accessibility 权限提示只显示一次

**What goes wrong:** `kAXTrustedCheckOptionPrompt: true` 只会在首次安装时显示系统对话框，后续拒绝后不会再次提示。

**Why it happens:** Apple 设计为防止应用骚扰用户，对话框只显示一次。

**How to avoid:**
1. 检测权限状态并显示自定义 UI 提示
2. 提供按钮打开 System Settings → Privacy & Security → Accessibility
3. 监听权限变化通知，实时更新 UI

**Warning signs:**
- 权限拒绝但功能无 UI 反馈
- 用户不知道需要授权

## Code Examples

### FIX-01: 修复单例状态观察

**方案 A: App 入口使用 @StateObject**
```swift
// VibeIslandMenuBar.swift
@main
struct VibeIslandMenuBar: App {
    // 使用 @StateObject 持有单例引用
    @StateObject private var stateManager = StateManager.shared
    @StateObject private var menuBarManager = MenuBarManager.shared
    
    var body: some Scene {
        MenuBarExtra("Vibe Island", systemImage: "sparkles") {
            ExpandedDetailsView()
                .environmentObject(stateManager)
        }
        .menuBarExtraStyle(.window)
    }
}
```

**方案 B: 子视图使用 @EnvironmentObject**
```swift
// ExpandedDetailsView.swift
struct ExpandedDetailsView: View {
    // 从环境接收，不再初始化
    @EnvironmentObject var stateManager: StateManager
    
    var body: some View {
        // 直接使用 stateManager
    }
}

// CompactStatusView.swift - 同样修改
struct CompactStatusView: View {
    @EnvironmentObject var stateManager: StateManager
    @EnvironmentObject var menuBarManager: MenuBarManager
    
    var body: some View {
        // 使用注入的状态管理器
    }
}
```

### FIX-02: macOS 音频配置

```swift
// SoundManager.swift 修改
import AVFAudio

class SoundManager {
    static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        configureAudioSession()
        loadSoundFile()
    }
    
    // 新增：macOS 音频会话配置
    private func configureAudioSession() {
        #if os(macOS)
        // macOS 使用 AVAudioApplication
        do {
            try AVAudioApplication.setCategory(.playback, mode: .default)
            print("✅ macOS 音频 category 已配置")
        } catch {
            print("⚠️ 配置音频 category 失败: \(error)")
        }
        #else
        // iOS 使用 AVAudioSession
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print("⚠️ 配置音频 category 失败: \(error)")
        }
        #endif
    }
    
    func playStateChangeSound() {
        guard isSoundEnabled else { return }
        guard !isSystemMuted() else { return }
        
        // macOS 菜单栏应用需要激活才能播放
        #if os(macOS)
        NSApplication.shared.activate(ignoringOtherApps: true)
        #endif
        
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
}
```

### FIX-03: Accessibility 权限管理

```swift
// 新建 AccessibilityManager.swift
import ApplicationServices
import Combine
import Cocoa

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var hasPermission: Bool = false
    @Published var hasPromptedUser: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkPermission(promptUser: false)
        startMonitoring()
    }
    
    /// 检查权限，可选是否提示用户
    func checkPermission(promptUser: Bool) {
        let options: CFDictionary?
        if promptUser {
            options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        } else {
            options = nil
        }
        
        hasPermission = AXIsProcessTrustedWithOptions(options)
        
        if promptUser {
            hasPromptedUser = true
        }
        
        print("Accessibility 权限状态: \(hasPermission ? "已授权" : "未授权")")
    }
    
    /// 启动权限变化监听
    func startMonitoring() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.hasPermission = AXIsProcessTrusted()
            print("权限变化通知: \(notification.name)")
        }
    }
    
    /// 打开系统设置中的 Accessibility 页面
    func openAccessibilitySettings() {
        // macOS 13+ 使用新的 URL scheme
        if #available(macOS 13.0, *) {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
            NSWorkspace.shared.open(url!)
        } else {
            // macOS 12 及之前
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security")
            NSWorkspace.shared.open(url!)
        }
    }
}
```

**UI 提示视图:**
```swift
// PermissionPromptView.swift
struct PermissionPromptView: View {
    @ObservedObject var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        if !accessibilityManager.hasPermission {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 32))
                
                Text("需要 Accessibility 权限")
                    .font(.headline)
                
                Text("Vibe Island 需要监控终端窗口标题以检测 Claude Code 状态。")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("授权") {
                    accessibilityManager.checkPermission(promptUser: true)
                }
                .buttonStyle(.borderedProminent)
                
                Button("打开系统设置") {
                    accessibilityManager.openAccessibilitySettings()
                }
                .buttonStyle(.bordered)
                
                Text("设置路径：系统设置 → 隐私与安全性 → 辅助功能")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| @ObservedObject 初始化单例 | @StateObject 或 @EnvironmentObject | SwiftUI 2020+ | 防止状态丢失 |
| AVAudioSession (iOS) | AVAudioApplication (macOS) | macOS 11+ | 正确的平台 API |
| AXIsProcessTrusted() (deprecated) | AXIsProcessTrustedWithOptions() | macOS 10.9 | 支持提示用户 |
| 无权限 UI 反馈 | 自定义 UI + 系统设置链接 | macOS 13+ | 用户体验改善 |

**Deprecated/outdated:**
- `AXIsProcessTrusted()`: 使用 `AXIsProcessTrustedWithOptions()` 代替
- `AVAudioSession.sharedInstance()` on macOS: 使用 `AVAudioApplication` 代替

## Open Questions

1. **是否需要在 App 启动时自动请求 Accessibility 权限？**
   - What we know: `kAXTrustedCheckOptionPrompt` 只显示一次系统对话框
   - What's unclear: 用户首次拒绝后，最佳 UX 是立即显示自定义提示还是延迟
   - Recommendation: 在 WindowMonitor 启动时检查，如果未授权则显示简洁提示

2. **音效播放是否需要考虑其他应用音频？**
   - What we know: `.playback` category 可与其他应用混音
   - What's unclear: 是否需要独占音频以确保音效明显
   - Recommendation: 使用 `.mixWithOthers` 选项，避免打断用户音乐/视频

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| macOS 14+ | SwiftUI MenuBarExtra | ✓ | Darwin 25.4.0 | — |
| AVFoundation | SoundManager | ✓ | System framework | — |
| ApplicationServices | AccessibilityManager | ✓ | System framework | — |
| Swift 5.9+ | Package | ✓ | System | — |

**Missing dependencies with no fallback:**
- None — all required frameworks are macOS system frameworks

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest |
| Config file | Package.swift (SPM configuration) |
| Quick run command | `swift test --filter VibeIslandTests` |
| Full suite command | `swift test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIX-01 | Singleton state persists across view updates | unit | `swift test --filter StateManagerTests.testSingleton` | ✅ |
| FIX-01 | @StateObject prevents state loss | unit | `swift test --filter VibeIslandMenuBarTests` | ✅ (needs update) |
| FIX-02 | Audio plays in menu bar context | unit | `swift test --filter SoundManagerTests.testPlayStateChangeSoundWhenEnabled` | ✅ (needs update) |
| FIX-03 | Permission check returns valid status | unit | New test file needed | ❌ Wave 0 |
| FIX-03 | Permission prompt UI shows when denied | UI | Manual verification | Manual only |

### Sampling Rate
- **Per task commit:** `swift test --filter VibeIslandTests`
- **Per wave merge:** `swift test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `VibeIslandTests/AccessibilityManagerTests.swift` — covers FIX-03 permission checking
- [ ] Update `VibeIslandTests/SoundManagerTests.swift` — add AVAudioApplication configuration test
- [ ] Update `VibeIslandTests/StateManagerTests.swift` — add @StateObject pattern verification
- [ ] `VibeIslandTests/PermissionPromptViewTests.swift` — UI test for permission denial scenario

## Sources

### Primary (HIGH confidence)
- [Apple Developer Documentation - AXIsProcessTrustedWithOptions](https://developer.apple.com/documentation/coreservices/1445445-axisprocesstrustedwithoptions) - API reference
- [Apple Developer Documentation - AVAudioApplication](https://developer.apple.com/documentation/avfaudio/avaudioapplication) - macOS audio API
- [Apple Developer Forums - @StateObject vs @ObservedObject](https://developer.apple.com/forums/thread/685772) - SwiftUI state management guidance

### Secondary (MEDIUM confidence)
- [Stack Overflow - Requesting Accessibility Permissions on macOS](https://stackoverflow.com/questions/39711880/requesting-accessibility-permissions-on-macos-swift) - Implementation examples
- [Hacking with Swift - Checking for Accessibility Permissions](https://www.hackingwithswift.com/example-code/system/how-to-check-if-your-app-has-been-granted-accessibility-access) - Code examples
- [Avanderlee.com - Accessibility Permissions in macOS](https://www.avanderlee.com/swift/accessibility-permissions-macos/) - Comprehensive guide

### Tertiary (LOW confidence)
- WebSearch findings from multiple community sources - verified against official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - macOS 系统框架，API 稳定
- Architecture: HIGH - SwiftUI 单例模式是官方推荐实践
- Pitfalls: HIGH - 问题已通过 WebSearch 和官方文档验证

**Research date:** 2026-04-03
**Valid until:** 30 days - macOS API 稳定，SwiftUI 模式变化缓慢