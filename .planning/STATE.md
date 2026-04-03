---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: kpbl
status: planning
last_updated: "2026-04-03T15:45:00.000Z"
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State: Vibe Island (kpbl)

**Started:** 2026-04-03
**Current Status:** Defining requirements

---

## Project Reference

**Core Value:** Never lose track of which agent conversation needs your attention — see all agent states in one glance without switching terminals

**Current Focus:** Milestone v2.0 kpbl — 自用版本迭代

**Platform:** macOS 14+
**Agent Support:** Claude Code only
**Project Code:** kpbl

---

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-04-03 — Milestone v2.0 kpbl started

---

## Accumulated Context (from v1.0 MVP)

### Architecture Decisions

**Two-target architecture confirmed:**
- Main App: Background monitoring service (socket, state management, system integration)
- Widget Extension: Dynamic Island UI rendering only

**Technology stack:**
- Swift 5.9+ (required for modern macOS APIs)
- SwiftUI + WidgetKit (Dynamic Island support via TimelineProvider)
- Network framework (NWConnection) for socket communication
- App Groups for inter-process data sharing
- AppKit for terminal control (where SwiftUI insufficient)

### Key Technical Constraints

- **WidgetKit update latency:** WidgetKit doesn't provide real-time updates. Must use TimelineEntry.relevance and reloadTimelines() on state changes.
- **App Groups requirement:** Main app and widget cannot share data without proper App Groups setup.
- **Socket robustness:** Must implement exponential backoff for reconnection, handle errors gracefully.
- **Terminal variability:** iTerm2 and Terminal.app have different AppleScript dictionaries; support must handle both.
- **AppleScript integration:** Terminal control uses NSAppleScript to execute AppleScript commands for tab switching.

### v1.0 MVP Deliverables

**DMG Installer:** `/Users/Zhuanz/island/island/VibeIsland-1.0.0.dmg`
**Xcode Project:** `/Users/Zhuanz/island/island/island.xcodeproj`

---

## v2.0 kpbl Context

### 商业版 vs 自用版差距分析

| 功能模块 | 商业版 | 自用版当前 | 差距程度 |
|----------|--------|------------|----------|
| **数据来源** | Socket JSON实时推送 | 进程+窗口推断 | 🔴 核心差距 |
| **菜单栏图标** | 动态圆点+徽章 | 固定"sparkles" | 🔴 显著差距 |
| **状态精度** | 8种精确状态 | 3种粗略状态 | 🟡 中等差距 |
| **终端跳转** | 精确tabId跳转 | 无法精确跳转 | 🟡 中等差距 |
| **音效系统** | ✅ 完整 | ❌ 无 | 🟢 可选功能 |

### 自用版特点

- 不依赖服务端，独立运行
- 通过进程检测(sysctl)和窗口标题解析推断状态
- 更轻量，但精度较低

---
*State initialized: 2026-04-03*
*Last updated: 2026-04-03 — Milestone v2.0 kpbl started*