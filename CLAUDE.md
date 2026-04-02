# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目规范

1. **代码注释使用中文** - 所有代码注释必须用中文编写
2. **文档输出使用中文** - 生成的文档、README、PRD 等均使用中文编写

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Vibe Island**
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## 核心框架
| 技术 | 版本 | 信心 | 理由 |
|------|------|------|------|
| **Swift** | 5.9+ | 高 | Apple 平台的官方语言，现代 macOS API 必需 |
| **SwiftUI** | macOS 14+ | 高 | 声明式 UI 框架，通过 WidgetKit 原生支持动态岛 |
| **WidgetKit** | macOS 14+ | 高 | 动态岛实时活动必需的框架 |
| **ActivityKit** | iOS 16.1+ / macOS 不适用 | 中 | iOS 专用于实时活动。macOS 动态岛使用 WidgetKit 的紧凑/展开视图 |
| **AppKit** | 最新 | 中 | 更深度的系统集成（菜单栏、辅助功能）在 SwiftUI 不足时需要 |
## 动态岛实现
| 技术 | 版本 | 信心 | 理由 |
|------|------|------|------|
| **WidgetExtension** | macOS 14+ | 高 | 在动态岛中显示 widget/实时活动必需 |
| **TimelineProvider** | WidgetKit | 高 | 向 widget/动态岛视图提供数据更新 |
| **App Intent** | 最新 | 中 | 从动态岛交互中打开主应用 |
## 套接字通信
| 技术 | 版本 | 信心 | 理由 |
|------|------|------|------|
| **Network framework** | Foundation | 高 | Swift 标准网络，原生支持 TCP/Unix 套接字 |
| **NWConnection** | 最新 | 高 | 现代、基于 async/await 的套接字 API |
## 进程监控
| 技术 | 版本 | 信心 | 理由 |
|------|------|------|------|
| **NSRunningApplication** | AppKit | 高 | 监控外部应用生命周期，bundle ID 匹配 |
| **NSWorkspace** | AppKit | 高 | 应用启动/终止的系统工作区通知 |
| **ProcessInfo** | Foundation | 中 | 基本进程信息 |
## 音效
| 技术 | 版本 | 信心 | 理由 |
|------|------|------|------|
| **AVFoundation** | 最新 | 高 | 音频播放的系统框架 |
| **AVAudioPlayer** | 最新 | 高 | 短音效的简单 API |
| **System Sound Services** | 最新 | 中 | 非常短的 UI 音效的替代方案，但不够灵活 |
## 终端集成
| 技术 | 版本 | 信心 | 理由 |
|------|------|------|------|
| **AppleScript** | 最新 | 中 | 可通过 AppleScript 控制 iTerm2、Terminal.app |
| **NSWorkspace URLs** | 最新 | 高 | 打开特定 URL，可能支持 terminal:// 或自定义方案 |
| **Accessibility APIs** | 最新 | 低 | 复杂但可模拟 UI 交互，MVP 不推荐 |
## 不使用的技术
| 技术 | 原因 |
|------|------|
| **Electron / Tauri** | 菜单栏/动态岛应用的开销，无法使用原生 WidgetKit |
| **Objective-C** | SwiftUI/WidgetKit 优先 Swift，样板代码更少 |
| **Combine（大量）** | Swift 的现代 async/await 对此用例更简单 |
| **Socket C 库** | Swift 的 Network framework 足够，更类型安全 |
| **基于自定义窗口的 UI** | 动态岛仅限 widget，主应用甚至不需要可见窗口 |
## 构建系统
| 技术 | 版本 | 信心 | 理由 |
|------|------|------|------|
| **Xcode** | 15.0+ | 高 | Apple 开发必需，最新 macOS SDK 支持 |
| **Swift Package Manager** | 最新 | 高 | 原生依赖管理，比 CocoaPods 更简单 |
## 部署
| 技术 | 版本 | 信心 | 理由 |
|------|------|------|------|
| **App Store Connect** | 最新 | 高 | 主要分发渠道 |
| **Developer ID** | 最新 | 中 | 用于 App Store 之外的直接分发（如需要） |
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
