# Technology Stack

**Project:** Vibe Island v2.0 (kpbl)
**Researched:** 2026-04-03
**Milestone:** Dynamic menu bar icons, enhanced status detection, sound effects

---

## Overview

本 milestone 在已验证的 MVP 架构基础上，添加动态菜单栏图标生成和状态检测增强功能。核心变更集中在**图标渲染层**和**状态检测精度**，无需引入新的外部依赖。

---

## Existing Stack (已验证，无需变更)

| 技术 | 版本 | 用途 | 状态 |
|------|------|------|------|
| **SwiftUI** | macOS 14+ | MenuBarExtra 入口、紧凑/展开视图 | 已实现 |
| **AppKit** | 最新 | NSRunningApplication 进程检测 | 已实现 |
| **Network framework** | Foundation | SocketMonitor TCP 连接 | 已实现 |
| **AVFoundation** | 最新 | SoundManager 音效播放 | 已实现 |
| **Accessibility API** | macOS | WindowMonitor 窗口标题解析 | 已实现 |
| **sysctl/libproc** | Darwin | ProcessMonitor 进程列表 | 已实现 |
| **App Groups** | macOS | SharedContainer 数据共享 | 已实现 |
| **Combine** | 最新 | 状态变化订阅 | 已实现 |

---

## New Stack Additions

### 1. Dynamic Menu Bar Icon Generation

**无需外部依赖，使用现有 AppKit API。**

| API | 用途 | 理由 |
|-----|------|------|
| **NSImage lockFocus/unlockFocus** | 动态图标绘制 | macOS 标准 API，直接绘制圆点/徽章 |
| **Core Graphics (CGContext)** | 复杂图形渲染 | 需要渐变/阴影时使用，当前需求简单 |
| **NSImage.template** | 模板图像模式 | 自动适配 light/dark mode，Apple 推荐 |
| **ImageRenderer (SwiftUI)** | 渲染 SwiftUI 视图到图像 | 备选方案，当前需求用 NSImage 更简洁 |

**推荐实现：**
```swift
// 动态菜单栏图标生成器
func createMenuBarIcon(statusCounts: StatusCounts) -> NSImage {
    let size = NSSize(width: 22, height: 18)  // 菜单栏标准尺寸
    return NSImage(size: size, flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

        // 绘制状态圆点（水平排列）
        var xOffset: CGFloat = 2
        for color in statusColors {
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: xOffset, y: 4, width: 10, height: 10))
            xOffset += 12
        }

        // 绘制数量徽章（如果有多个代理）
        if totalCount > 1 {
            drawBadge(ctx, count: totalCount, at: CGRect(x: rect.width - 12, y: 0, width: 12, height: 12))
        }

        return true
    }.withRenderingMode(.alwaysTemplate)  // 关键：模板模式自动适配主题
}
```

**关键参数：**
- 图标尺寸：22x18 points（菜单栏标准）
- 圆点尺寸：10x10 points
- 徽章尺寸：12x12 points
- 必须设置 `.template` 渲染模式

---

### 2. Enhanced Status Detection

**无需外部依赖，使用现有 Darwin/AppKit API 增强精度。**

| API | 新用途 | 理由 |
|-----|--------|------|
| **CGWindowListCopyWindowInfo** | 全局窗口枚举 | 比 AXUIElement 更可靠获取窗口标题 |
| **proc_pid_rusage** | CPU/内存使用检测 | Darwin C API，获取进程资源使用 |
| **proc_pidinfo** | 进程详细信息 | 已使用，扩展获取更多状态字段 |
| **NSRunningApplication.activationPolicy** | 应用活跃状态 | 判断终端是否为前台应用 |

**推荐实现 - 窗口标题检测增强：**
```swift
// 使用 CGWindowList API（比 AXUIElement 更可靠）
func getAllTerminalWindows() -> [WindowInfo] {
    let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]

    var windows: [WindowInfo] = []
    for window in windowList ?? [] {
        guard let ownerName = window[kCGWindowOwnerName as String] as? String,
              terminalBundleIds.contains(ownerName.lowercased()) else { continue }

        let title = window[kCGWindowName as String] as? String ?? ""
        let windowNumber = window[kCGWindowNumber as String] as? Int ?? 0

        windows.append(WindowInfo(title: title, windowId: windowNumber, owner: ownerName))
    }
    return windows
}
```

**推荐实现 - CPU/内存监控（可选）：**
```swift
// 获取进程 CPU 使用率
func getProcessCPUUsage(pid: Int32) -> Double? {
    var rusage = proc_rusage()
    let result = proc_pid_rusage(pid, RUSAGE_INFO_V2, &rusage)

    if result == 0 {
        // 计算 CPU 使用率
        return calculateCPUFromRusage(rusage)
    }
    return nil
}
```

---

### 3. Sound Effects System

**已实现 SoundManager，无需变更。**

当前实现已满足需求：
- AVAudioPlayer 音效播放
- 系统静音检测（通过 AppleScript）
- 频率限制（防重复播放）
- UserDefaults 音效开关持久化

**唯一建议：**
- 添加更多音效文件（不同状态变化不同音效）
- 当前只有 `state_update.aiff`，可扩展为：
  - `approval_required.aiff` - 等待审批时
  - `task_complete.aiff` - 任务完成时
  - `error.aiff` - 错误状态

---

## Integration Points

### 与现有架构的集成点

| 新组件 | 集成位置 | 方式 |
|--------|----------|------|
| **DynamicIconGenerator** | MenuBarExtra 入口 | 替换静态 `systemImage: "sparkles"` |
| **CGWindowListMonitor** | WindowMonitor 扩展 | 作为补充检测机制 |
| **ProcUsageMonitor** | ProcessMonitor 扩展 | 可选，添加资源使用信息 |
| **EnhancedStatusParser** | WindowMonitor.parseWindowTitle | 增强状态识别精度 |

### 数据流变化

```
现有流程：
SocketMonitor -> StateManager -> CompactStatusView (静态圆点)
                                 -> ExpandedDetailsView

新增流程：
StateManager -> DynamicIconGenerator -> MenuBarExtra (动态图标)
WindowMonitor + CGWindowList -> EnhancedStatusParser -> StateManager
```

---

## No-Go List

**明确不需要引入的技术：**

| 技术 | 原因 |
|------|------|
| **第三方图标库** | NSImage/Core Graphics 足够，引入依赖增加复杂度 |
| **Electron/Tauri** | 原生 SwiftUI 性能更好，无 WidgetKit 支持 |
| **Combine 大量使用** | async/await 更简洁，已用 Combine 仅用于通知订阅 |
| **Objective-C 桥接** | 所有 API 都有 Swift 接口 |
| **Core Animation** | 菜单栏图标不需要复杂动画，SwiftUI animation 足够 |
| **通知中心扩展** | MenuBarExtra 已提供足够 UI，不需要 Notification Content Extension |
| **ScreenCaptureKit** | CGWindowListCopyWindowInfo 更轻量，权限要求更低 |

---

## Version Requirements

| 技术 | 最低版本 | 推荐版本 | 理由 |
|------|----------|----------|------|
| macOS | 14.0 (Sonoma) | 14.0+ | MenuBarExtra 稳定版本 |
| Swift | 5.9 | 5.10+ | 现代 async/await 支持 |
| Xcode | 15.0 | 16.0+ | 最新 SwiftUI 调试工具 |

---

## Installation

**无需额外安装。** 所有新功能使用现有 macOS SDK API。

现有依赖（已配置）：
```bash
# 无外部依赖，仅使用系统框架
import SwiftUI          # macOS SDK
import AppKit           # macOS SDK
import AVFoundation     # macOS SDK
import Network          # Foundation
import Darwin           # sysctl/libproc
```

---

## Sources

| 来源 | 置信度 | 内容 |
|------|--------|------|
| 现有代码分析 | HIGH | ProcessMonitor, WindowMonitor, SoundManager 实现 |
| Apple NSImage 文档 | HIGH | 模板图像、lockFocus 绘制 |
| Apple Accessibility API | HIGH | AXUIElement、CGWindowListCopyWindowInfo |
| Darwin libproc | HIGH | proc_pid_rusage、proc_pidinfo |
| SwiftUI MenuBarExtra | HIGH | 动态 image 参数支持 |

---

## Summary

本 milestone 不需要引入新的外部依赖。核心变更：

1. **动态图标**：使用 NSImage 手动绘制，设置 template 模式
2. **状态检测增强**：添加 CGWindowListCopyWindowInfo 作为补充检测机制
3. **音效**：保持现有 AVAudioPlayer 实现

所有功能通过现有 macOS SDK API 实现，保持架构简洁。