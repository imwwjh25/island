# Stack Research: Vibe Island

**Last Updated:** 2026-04-02
**Domain:** macOS Dynamic Island App Development

## Core Framework

| Technology | Version | Confidence | Rationale |
|------------|---------|------------|-----------|
| **Swift** | 5.9+ | High | Official language for Apple platforms, required for modern macOS APIs |
| **SwiftUI** | macOS 14+ | High | Declarative UI framework with native Dynamic Island support via WidgetKit |
| **WidgetKit** | macOS 14+ | High | Required framework for Dynamic Island Live Activities |
| **ActivityKit** | iOS 16.1+ / macOS N/A | Medium | iOS-only for Live Activities. macOS Dynamic Island uses WidgetKit with compact/expanded views |
| **AppKit** | Latest | Medium | Required for deeper system integration (menubar, accessibility) if SwiftUI insufficient |

## Dynamic Island Implementation

| Technology | Version | Confidence | Rationale |
|------------|---------|------------|-----------|
| **WidgetExtension** | macOS 14+ | High | Required for widgets/Live Activities displayed in Dynamic Island |
| **TimelineProvider** | WidgetKit | High | Provides data updates to widget/Dynamic Island views |
| **App Intent** | Latest | Medium | Enables opening your main app from Dynamic Island interactions |

## Socket Communication

| Technology | Version | Confidence | Rationale |
|------------|---------|------------|-----------|
| **Network framework** | Foundation | High | Swift's standard networking, supports TCP/Unix sockets natively |
| **NWConnection** | Latest | High | Modern, async/await-based socket API |

## Process Monitoring

| Technology | Version | Confidence | Rationale |
|------------|---------|------------|-----------|
| **NSRunningApplication** | AppKit | High | Monitors external app lifecycle, bundle ID matching |
| **NSWorkspace** | AppKit | High | System workspace notifications for app launch/terminate |
| **ProcessInfo** | Foundation | Medium | Basic process information |

## Sound Effects

| Technology | Version | Confidence | Rationale |
|------------|---------|------------|-----------|
| **AVFoundation** | Latest | High | System framework for audio playback |
| **AVAudioPlayer** | Latest | High | Simple API for short sound effects |
| **System Sound Services** | Latest | Medium | Alternative for very short UI sounds, but less flexible |

## Terminal Integration

| Technology | Version | Confidence | Rationale |
|------------|---------|------------|-----------|
| **AppleScript** | Latest | Medium | Can control iTerm2, Terminal.app via AppleScript |
| **NSWorkspace URLs** | Latest | High | Opens specific URLs, may support terminal:// or custom schemes |
| **Accessibility APIs** | Latest | Low | Complex but can simulate UI interactions, not recommended for MVP |

## What NOT to Use

| Technology | Reason |
|------------|--------|
| **Electron / Tauri** | Overhead for menubar/Dynamic Island app, cannot use native WidgetKit |
| **Objective-C** | SwiftUI/WidgetKit are Swift-first, less boilerplate |
| **Combine (extensively)** | Swift's modern async/await is simpler for this use case |
| **Socket C libraries** | Swift's Network framework is sufficient, more type-safe |
| **Custom window-based UI** | Dynamic Island is widget-only, main app may not even need visible window |

## Build System

| Technology | Version | Confidence | Rationale |
|------------|---------|------------|-----------|
| **Xcode** | 15.0+ | High | Required for Apple development, latest macOS SDK support |
| **Swift Package Manager** | Latest | High | Native dependency management, simpler than CocoaPods |

## Deployment

| Technology | Version | Confidence | Rationale |
|------------|---------|------------|-----------|
| **App Store Connect** | Latest | High | Primary distribution channel |
| **Developer ID** | Latest | Medium | For direct distribution outside App Store (if needed) |

---
*Research completed: 2026-04-02*