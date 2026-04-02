# Project Research Summary

**Project:** Vibe Island
**Domain:** macOS Dynamic Island System Utility
**Researched:** 2026-04-02
**Confidence:** HIGH

## Executive Summary

Vibe Island is a macOS system utility that monitors Claude Code CLI activity via socket connections and displays agent states in the Dynamic Island. Experts build this type of app using a two-target architecture with a background main app for monitoring and a widget extension for Dynamic Island rendering. The recommended approach uses Swift, SwiftUI, and WidgetKit (macOS 14+) with App Groups for inter-process communication.

The core architecture separates concerns: the main app handles socket monitoring, state management, and system integration, while the widget extension focuses solely on Dynamic Island UI rendering. Key risks include WidgetKit's non-real-time update latency, proper App Groups configuration for data sharing, and robust socket connection handling. These should be addressed early with proper state persistence, graceful degradation, and comprehensive testing across multiple terminal emulators.

## Key Findings

### Recommended Stack

Vibe Island requires native Apple technologies since Dynamic Island APIs are unavailable in cross-platform frameworks. The research clearly identifies Swift 5.9+, SwiftUI, and WidgetKit as mandatory for macOS 14+ Dynamic Island support.

**Core technologies:**
- **Swift 5.9+** — Official language for Apple platforms, required for modern macOS APIs
- **SwiftUI + WidgetKit** — Declarative UI framework with native Dynamic Island support via TimelineProvider
- **WidgetExtension** — Required target for widgets displayed in Dynamic Island
- **Network framework (NWConnection)** — Modern async/await-based socket API for Claude Code communication
- **App Groups** — Critical for sharing data between main app and widget extension
- **AppKit** — Required for process monitoring and terminal control when SwiftUI insufficient

### Expected Features

Vibe Island is a system utility, not a content app. The main app may be invisible (menubar-only), with the Dynamic Island widget being the primary user interface. Real-time updates and low resource usage are critical.

**Must have (table stakes):**
- **Compact/Expanded states** — Users expect tap-to-expand with fluid transitions
- **Real-time state updates** — Dynamic Island must reflect actual agent state, not stale data
- **State persistence** — Must survive app backgrounding and termination
- **Multi-agent display** — Show all active Claude Code agents in one view
- **Tap interactions** — Standard gesture for expanding/collapsing and opening main app

**Should have (competitive):**
- **Auto-expand on state change** — Automatically expand when user attention needed (e.g., awaiting approval)
- **Terminal tab jumping** — Direct navigation to specific terminal tab (high complexity, high value)
- **Custom sound effects** — Unique audio feedback for state transitions
- **Error handling** — Graceful degradation when data unavailable

**Defer (v2+):**
- **Activity history** — Quick access to recent completed tasks
- **Priority indicators** — Visual distinction for urgent tasks
- **Custom animation curves** — Unique feel vs standard Apple animations

### Architecture Approach

The architecture uses a two-target split: Main App (background monitoring service) and Widget Extension (UI rendering). Data flows from Claude Code via socket to Socket Monitor, through State Manager (with persistence), to Widget Coordinator which triggers Widget Center timeline reloads. The widget extension reads from shared container and renders compact/expanded Dynamic Island views.

**Major components:**
1. **Socket Monitor** — Listens for Claude Code socket connections, parses JSON messages
2. **State Manager** — Central state storage, change events, persistence via UserDefaults
3. **Widget Coordinator** — Triggers WidgetCenter.shared.reloadTimelines() on state changes
4. **VibeIslandWidget** — TimelineProvider implementation, Dynamic Island compact/expanded views
5. **Terminal Controller** — Handles terminal app detection and tab jumping via AppleScript

### Critical Pitfalls

Research identified 14 pitfalls with specific prevention strategies and phase assignments. The most critical for MVP involve WidgetKit behavior, inter-process communication, and system integration.

1. **WidgetKit Update Latency** — WidgetKit doesn't provide real-time updates. Use appropriate TimelineEntry.relevance and reloadTimelines() immediately on state changes. Consider local notification fallback for critical events.
2. **App Group / Shared Container Misconfiguration** — Main app and widget cannot share data without proper setup. Enable App Groups with identical group identifier, test data flow before UI work.
3. **Socket Connection Not Robust** — Implement exponential backoff for reconnection, handle errors gracefully, use async/await, test Claude Code restart and sleep/wake scenarios.
4. **Widget State Not Persisted** — Persist agent state to UserDefaults on every update, load on app launch, test persistence by quitting and restarting.
5. **Terminal App Detection Fails** — Detect by bundle ID not path, support Terminal.app and iTerm2, provide fallback behavior, use AppleScript for portability.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Data Layer Foundation
**Rationale:** Shared container and state persistence must be verified before UI work. This prevents Pitfall #2 (App Group misconfiguration) and #8 (no persistence), which would break core functionality.
**Delivers:** Working App Groups configuration, Socket Monitor with basic JSON parsing, State Manager with persistence, shared data models
**Addresses:** Real-time updates, state persistence, multi-agent data model
**Avoids:** App Group misconfiguration, unpersisted state, socket connection fragility

### Phase 2: Main App Core
**Rationale:** Background monitoring and system integration come before widget rendering. This addresses Pitfall #1 (update latency), #6 (socket robustness), and #7 (sound effects appropriateness).
**Delivers:** Robust socket connection with exponential backoff, Widget Coordinator with timeline reload triggers, Sound Manager with mute detection, Process Monitor for terminal detection
**Uses:** Network framework (NWConnection), AppKit (NSRunningApplication), AVFoundation
**Implements:** Socket Monitor, State Manager, Widget Coordinator, Sound Manager, Process Monitor
**Avoids:** WidgetKit update latency, fragile socket connections, inappropriate sound playback

### Phase 3: Dynamic Island Widget
**Rationale:** Widget UI requires working state feed from main app. This is where Pitfall #3 (wrong APIs), #4 (accessibility), and #10 (appearance adaptation) must be avoided.
**Delivers:** Widget Extension target, TimelineProvider reading from shared container, CompactView and ExpandedView SwiftUI components, accessibility support, light/dark mode adaptation
**Uses:** SwiftUI, WidgetKit, App Groups container
**Implements:** VibeIslandWidget, CompactView, ExpandedView, AgentCardView
**Avoids:** iOS ActivityKit confusion, missing accessibility support, appearance mismatch

### Phase 4: Integration & Terminal Control
**Rationale:** Terminal tab jumping is complex and requires working widget. This addresses Pitfall #5 (terminal detection) and #11/#12 (testing coverage).
**Delivers:** Terminal Controller with iTerm2 and Terminal.app support, graceful degradation for unsupported terminals, end-to-end integration tests, multi-terminal testing
**Uses:** AppKit, AppleScript, Accessibility APIs (minimal)
**Implements:** Terminal Controller, integration test suite
**Avoids:** Hardcoded terminal paths, silent failures, poor terminal app support

### Phase 5: Polish & Deployment
**Rationale:** Final polish before release. This addresses Pitfall #13 (version requirements) and #14 (App Store accessibility).
**Delivers:** Memory leak profiling, reduced motion support, App Store assets, deployment configuration, accessibility audit
**Addresses:** Activity history (if time permits), priority indicators (if time permits)
**Avoids:** Missing macOS 14+ requirement, App Store rejection for accessibility

### Phase Ordering Rationale

- **Data Layer first:** Shared container and state persistence are foundational. Without verified data flow between main app and widget, all subsequent work fails.
- **Main App Core before Widget:** Widget needs state feed from main app. Robust socket handling and timeline reload triggers must work before UI can display anything useful.
- **Widget before Integration:** Terminal control is an enhancement to the core experience. The widget must render and update correctly before adding terminal integration complexity.
- **Integration before Polish:** All core features working before optimization and deployment preparation.

**How this avoids pitfalls:**
- Phase 1 prevents App Group and persistence issues that would manifest everywhere
- Phase 2 addresses socket robustness and update latency before widget complexity added
- Phase 3 uses correct WidgetKit APIs from start, adds accessibility alongside UI
- Phase 4 tests with multiple terminals to avoid terminal-specific failures

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Integration):** Terminal tab jumping via AppleScript has medium confidence. Multiple terminal emulators have different AppleScript dictionaries. May need API research for each terminal.
- **Phase 5 (Polish):** App Store accessibility guidelines specific to Dynamic Island widgets are evolving. May need research on current review expectations.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Data Layer):** App Groups, UserDefaults, and socket parsing are well-documented with established patterns.
- **Phase 2 (Main App Core):** Network framework, AVFoundation, and AppKit process monitoring have extensive documentation.
- **Phase 3 (Widget):** WidgetKit TimelineProvider and SwiftUI Dynamic Island views are documented by Apple for macOS 14+.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Apple官方文档明确, WidgetKit和Dynamic Island在macOS 14+的支持路径清晰 |
| Features | HIGH | Dynamic Island交互模式有明确的Apple设计规范, 功能分类合理 |
| Architecture | HIGH | 双目标架构(主应用+Widget扩展)是标准模式, 组件边界清晰 |
| Pitfalls | HIGH | 14个陷阱都有具体的预防策略和阶段分配, 来源可靠 |

**Overall confidence:** HIGH

### Gaps to Address

Research is comprehensive for MVP. Minor gaps:

- **Terminal AppleScript specifics:** Exact AppleScript commands for iTerm2 tab jumping not detailed. Plan to research during Phase 4 planning or discover through experimentation.
- **WidgetKit update timing:** Exact latency numbers depend on system conditions. Research recommends measuring during Phase 4 integration testing.
- **App Store accessibility requirements:** Dynamic Island accessibility expectations may evolve. Plan to review latest guidelines before Phase 5 submission.

These gaps are not blockers — they can be addressed during phase planning or through incremental development/testing.

## Sources

### Primary (HIGH confidence)
- Apple WidgetKit Documentation — Dynamic Island support, TimelineProvider APIs, update mechanisms
- Apple SwiftUI Documentation — Declarative UI for macOS, view modifiers, accessibility
- Apple App Groups Documentation — Shared container setup, data sharing between app and widget

### Secondary (MEDIUM confidence)
- Community discussions on WidgetKit update latency — Common challenge with workarounds
- Terminal emulator AppleScript documentation — iTerm2 and Terminal.app scripting capabilities
- macOS Dynamic Island design guidelines — Apple's design principles for compact/expanded states

### Tertiary (LOW confidence)
- Third-party Dynamic Island widget examples — Limited open-source examples for macOS specifically
- Sound effect best practices — AVFoundation usage patterns, though standard framework

---
*Research completed: 2026-04-02*
*Ready for roadmap: yes*