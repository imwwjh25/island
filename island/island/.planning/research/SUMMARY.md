# Project Research Summary

**Project:** Vibe Island v2.0 (kpbl milestone)
**Domain:** macOS menu bar dynamic status indicator for Claude Code agents
**Researched:** 2026-04-03
**Confidence:** HIGH

## Executive Summary

Vibe Island v2.0 是一个 macOS 菜单栏应用，用于监控 Claude Code 代理的实时状态。本 milestone 核心目标是实现动态菜单栏图标，让用户无需展开即可了解代理状态，同时增强状态检测精度和完善音效系统。

**推荐方案：** 无需引入任何外部依赖，完全使用 macOS SDK 原生 API。动态图标通过 NSImage 手动绘制并设置 `.alwaysTemplate` 模式自动适配深浅色主题；状态检测增强使用 CGWindowListCopyWindowInfo 作为现有 AXUIElement 的补充机制；音效系统保持现有 AVAudioPlayer 实现，只需添加 AVAudioSession 正确配置。

**关键风险：** 现有代码存在 @ObservedObject 与单例对象错误组合的问题，可能导致状态丢失和内存泄漏；Accessibility 权限未检查可能导致窗口检测静默失败；AVAudioSession 未配置可能导致菜单栏应用中音效无法播放。这些基础设施问题必须在功能开发前修复。

## Key Findings

### Recommended Stack

本 milestone 不需要引入新的外部依赖，所有功能通过现有 macOS SDK API 实现。

**Core technologies:**
- **NSImage lockFocus/unlockFocus:** 动态图标绘制 — 菜单栏标准方式，直接绘制圆点和徽章
- **CGWindowListCopyWindowInfo:** 全局窗口枚举 — 比 AXUIElement 更可靠，补充检测机制
- **AVAudioSession:** 音频会话配置 — 解决菜单栏应用音效播放问题
- **.alwaysTemplate rendering:** 图标主题适配 — 自动适配 light/dark mode

**标准参数：**
- 菜单栏图标尺寸：22x18 points
- 状态圆点尺寸：10x10 points
- 数量徽章尺寸：12x12 points

### Expected Features

**Must have (table stakes):**
- 动态图标生成 — 无需展开即可识别状态
- 状态圆点 + 数量徽章 — 最直观的状态显示
- 点击展开详情 — 标准菜单栏交互模式
- 跳转到终端 — 核心功能，快速定位代理
- 音效提示 — "Vibe" 体验核心

**Should have (differentiators):**
- 闪烁/脉冲动画 — 吸引注意力，不打扰
- 状态检测增强 — 提升识别准确率
- CPU/内存使用显示 — 了解代理资源占用（延后 v2.1）

**Defer (v2+):**
- WezTerm 等多终端支持 — MVP 仅 iTerm2/Terminal
- 状态历史记录 — 需要 v3+ 架构支持
- 自定义音效 — 体验优化，非阻塞

### Architecture Approach

推荐在现有 MenuBarManager 协调模式下添加 DynamicIconGenerator 组件，从 StateManager 读取聚合状态并生成模板图像。

**Major components:**
1. **DynamicIconGenerator (新增)** — 根据状态聚合生成 NSImage 模板图标
2. **StateManager (扩展)** — 添加状态聚合方法 getStatusCounts()
3. **WindowMonitor (扩展)** — 添加 CGWindowList 检测作为补充机制
4. **MenuBarManager (修改)** — 集成动态图标更新流程

**数据流：**
```
StateManager.agentStates 变化
    -> DynamicIconGenerator.createIcon(statusCounts)
    -> MenuBarExtra(image: dynamicIcon) 更新显示
```

### Critical Pitfalls

1. **@ObservedObject 与 Singleton 错误组合** — 当前 CompactStatusView 使用 `@ObservedObject private var stateManager = StateManager.shared`，应改为 `@StateObject` 或直接访问静态属性，避免视图重建时状态丢失

2. **MenuBarExtra 动态图标不支持绑定值** — `systemImage:` 参数是静态的，必须使用自定义 ImageProvider 或在状态变化时手动触发图标更新

3. **AVAudioPlayer 在菜单栏应用中不播放** — LSUIElement=true 应用默认无活跃音频会话，必须配置 AVAudioSession.setCategory(.playback) 并激活

4. **Accessibility API 权限缺失静默失败** — AXUIElement 调用在无权限时返回错误但不抛异常，必须在启动时调用 `AXIsProcessTrustedWithOptions()` 检查并提示用户授权

5. **多重监控器状态冲突** — SocketMonitor、WindowMonitor、ProcessMonitor 可能对同一 Agent 产生不同 ID，需统一 ID 生成策略和去重逻辑

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: 基础设施修复
**Rationale:** 现有代码存在多个可能导致功能失效的基础问题，必须先修复才能添加新功能
**Delivers:** 稳定的状态管理、音效播放、权限检查
**Addresses:** 现有功能稳定性
**Avoids:** Pitfall 1 (@ObservedObject 单例问题), Pitfall 3 (AVAudioSession), Pitfall 4 (Accessibility 权限)

### Phase 2: 动态图标实现
**Rationale:** 本 milestone 核心功能，依赖 Phase 1 的状态管理修复
**Delivers:** 菜单栏动态图标，无需展开即可了解状态
**Uses:** NSImage lockFocus, .alwaysTemplate rendering
**Implements:** DynamicIconGenerator 组件
**Avoids:** Pitfall 2 (MenuBarExtra 动态图标限制)

### Phase 3: 状态检测增强
**Rationale:** 提升状态识别准确率，为更可靠的动态图标提供数据基础
**Delivers:** CGWindowList 补充检测机制，更准确的窗口标题解析
**Uses:** CGWindowListCopyWindowInfo, proc_pid_rusage (可选)
**Implements:** WindowMonitor 扩展
**Avoids:** Pitfall 5 (多重监控器冲突)

### Phase 4: 优化和润色
**Rationale:** 功能完善后进行性能优化和体验提升
**Delivers:** 闪烁动画效果、音效扩展、性能优化
**Addresses:** P1 功能（闪烁提示）、P2 功能（音效扩展）

### Phase Ordering Rationale

- Phase 1 必须最先执行，现有代码存在会导致功能失效的基础问题
- Phase 2 是核心功能，依赖 Phase 1 的状态管理修复
- Phase 3 是增强功能，可与 Phase 2 并行但建议顺序执行以保证图标数据质量
- Phase 4 是优化项，应在核心功能稳定后进行

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** MenuBarExtra 动态图标更新机制需要实验验证，官方文档有限
- **Phase 3:** CGWindowList 与 AXUIElement 结果合并策略需要测试

Phases with standard patterns (skip research-phase):
- **Phase 1:** @StateObject 使用、AVAudioSession 配置、Accessibility 权限检查都是标准模式
- **Phase 4:** 动画和音效扩展使用现有 API，文档完善

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | 所有 API 都是 macOS SDK 标准，有官方文档支持 |
| Features | HIGH | 基于现有代码分析和 MVP 目标，需求明确 |
| Architecture | HIGH | 基于现有架构扩展，模式清晰 |
| Pitfalls | HIGH | Context7 和官方文档确认，多个 Stack Overflow 来源佐证 |

**Overall confidence:** HIGH

### Gaps to Address

- **MenuBarExtra 动态更新频率限制：** 需要在 Phase 2 实验测试实际表现，可能需要频率限制策略
- **图标更新触发机制：** StateManager 变化如何最优触发图标重绘需要实际测试
- **多代理场景性能：** 10+ 代理时的图标渲染和状态更新性能需要验证

## Sources

### Primary (HIGH confidence)
- 现有代码分析 — ProcessMonitor.swift, WindowMonitor.swift, SocketMonitor.swift, SoundManager.swift, StateManager.swift
- Apple NSImage/AppKit 文档 — 模板图像、lockFocus 绘制
- Apple Accessibility API 文档 — AXUIElement、权限要求
- Hacking with Swift — @StateObject vs @ObservedObject 使用规则

### Secondary (MEDIUM confidence)
- Stack Overflow — MenuBarExtra 动态图标讨论
- Stack Overflow — AVAudioPlayer 在菜单栏应用中的问题
- Apple Developer Forums — Focus Mode 音频行为

### Tertiary (LOW confidence)
- Darwin libproc 文档 — proc_pid_rusage CPU/内存监控（可选功能，延后 v2.1）

---
*Research completed: 2026-04-03*
*Ready for roadmap: yes*