# Roadmap: Vibe Island

**Created:** 2026-04-02
**Granularity:** Standard
**Total Phases:** 9 (5 in v1.0, 4 in v2.0)

## Milestones

- ✅ **v1.0 MVP** - Phases 1-5 (shipped 2026-04-02)
- 🚧 **v2.0 kpbl** - Phases 6-9 (in progress)

## Overview

Vibe Island delivers real-time Claude Code agent status monitoring in the macOS menu bar. The roadmap follows a dependency-driven approach: data layer foundation first, then main app core for monitoring, menu bar UI for display, terminal integration for enhancement, and polish for deployment. v2.0 adds dynamic menu bar icon, enhanced status detection, and improved sound system.

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) - SHIPPED 2026-04-02</summary>

### Phase 1: Data Layer Foundation

**Goal:** Shared data infrastructure enables main app and widget to communicate and persist state reliably

**Depends on:** Nothing (first phase)

**Requirements:** AGNT-01, AGNT-02, STMG-02, STMG-03

**Success Criteria** (what must be TRUE):
1. App connects to Claude Code via local socket and parses JSON messages successfully
2. App detects and stores multiple concurrent agent states in shared container
3. Agent states persist across app termination and relaunch
4. Shared container is accessible to both main app and widget extension

**Plans:** 1 plan
- [x] 01-data-layer-foundation-01-PLAN.md — 创建共享数据模型、状态管理器和套接字监控器

**Completed:** 2026-04-02

---

### Phase 2: Main App Core

**Goal:** Background monitoring detects state changes and provides sound feedback

**Depends on:** Phase 1

**Requirements:** AGNT-03, STMG-01, CORE-05, CORE-06, CORE-07, CORE-08

**Success Criteria** (what must be TRUE):
1. App detects when agent status changes (in_progress, complete, awaiting_approval)
2. App plays 8-bit pixel game sound effect when agent changes state
3. Sound effects respect system mute state (no sound when muted)
4. Widget reloads its timeline immediately after state change

**Plans:** 1 plan
- [x] 02-main-app-core-01-PLAN.md — 增强状态变化检测、实现音效系统、优化widget重新加载

**Completed:** 2026-04-02

---

### Phase 3: Dynamic Island Widget

**Goal:** Users view and interact with agent states in MenuBarExtra (macOS Dynamic Island alternative)

**Depends on:** Phase 2

**Requirements:** DIUI-01, DIUI-02, DIUI-03, DIUI-04, STMG-03, CORE-01, CORE-02, ACCS-01, ACCS-02, ACCS-03

**Success Criteria** (what must be TRUE):
1. User sees compact state with agent count and status summary
2. User can tap MenuBarExtra to expand to detailed view
3. User sees visual prompts when agent needs approval or completes (blinking, size change, badge)
4. User sees smooth animations between compact and expanded states
5. User can tap background to collapse expanded view
6. VoiceOver announces content correctly
7. MenuBarExtra UI adapts to system appearance (light/dark mode)
8. MenuBarExtra UI respects reduced motion accessibility setting

**Plans:** 4 plans
- [x] 03-dynamic-island-widget-00-PLAN.md — 创建测试基础设施（Wave 0 测试骨架）
- [x] 03-dynamic-island-widget-01-PLAN.md — 构建 MenuBarExtra UI（紧凑视图和展开视图）
- [x] 03-dynamic-island-widget-02-PLAN.md — 实现视觉提示功能（替代自动展开）
- [x] 03-dynamic-island-widget-03-PLAN.md — 添加辅助功能支持（VoiceOver、深色/浅色模式、减少动画）

**UI hint:** yes

**Completed:** 2026-04-02

---

### Phase 4: Terminal Integration

**Goal:** Users can jump to the terminal tab for specific agents

**Depends on:** Phase 3

**Requirements:** CORE-03, CORE-04

**Success Criteria** (what must be TRUE):
1. User can click agent card to jump to corresponding terminal tab in iTerm2
2. User can click agent card to jump to corresponding terminal tab in Terminal.app
3. Terminal app detection works correctly when multiple terminals are open
4. App provides feedback when terminal integration fails gracefully

**Plans:** 2 plans
- [x] 04-terminal-integration-01-PLAN.md — 创建 TerminalController 终端控制器
- [x] 04-terminal-integration-02-PLAN.md — 在 ExpandedDetailsView 中添加点击交互和错误反馈

**Completed:** 2026-04-03

---

### Phase 5: Polish & Deployment

**Goal:** 构建 macOS 应用并生成 DMG 安装包，用于 MVP 功能验证

**Depends on:** Phase 4

**Requirements:** (None - final polish phase)

**Success Criteria** (what must be TRUE - adjusted for MVP):
1. Xcode 项目构建成功，无编译错误
2. DMG 安装包创建成功
3. DMG 可以挂载，应用可以安装到 /Applications
4. 安装后的应用可以启动并运行
5. 基本功能验证通过（套接字监控、菜单栏 UI、终端跳转）

**Plans:** 2 plans
- [x] 05-polish-deployment-01-PLAN.md — 创建 Xcode 项目和构建配置
- [ ] 05-polish-deployment-02-PLAN.md — 创建 DMG 安装包和功能验证

**Note:** 此阶段针对 MVP 简化，不包含 App Store 提交、性能分析、完整辅助功能测试。目标是生成可安装的应用包用于功能验证。

</details>

---

### ✅ v2.0 kpbl (Complete)

**Milestone Goal:** 菜单栏 UI 和状态检测向商业版功能靠近，实现动态图标、增强检测和差异化音效

**Completed:** 2026-04-03

#### Phase 6: Infrastructure Fixes

**Goal:** 修复基础设施问题，确保后续功能正常工作

**Depends on:** Phase 5

**Requirements:** FIX-01, FIX-02, FIX-03

**Success Criteria** (what must be TRUE):
1. Singleton state manager persists correctly across view updates without state loss
2. Sound effects play correctly in menu bar application context
3. App requests Accessibility permission at launch and handles denial gracefully
4. User sees clear guidance when Accessibility permission is not granted

**Plans:** 2 plans
- [x] 06-01-PLAN.md — 修复 @StateObject 单例状态管理和 AccessibilityManager 集成
- [x] 06-02-PLAN.md — 配置 macOS audio session 和音效播放修复

**Completed:** 2026-04-03

---

#### Phase 7: Dynamic Menu Bar Icon

**Goal:** 用户无需展开菜单栏即可看到代理状态摘要

**Depends on:** Phase 6

**Requirements:** MENUBAR-01, MENUBAR-02, MENUBAR-03, MENUBAR-04, MENUBAR-05

**Success Criteria** (what must be TRUE):
1. User sees status dot in menu bar icon showing current agent state (in_progress/awaiting_approval/complete)
2. User sees badge count showing number of active agents
3. User sees pulsing animation when agents need attention (awaiting_approval)
4. User sees cyberpunk neon colors for status (cyan in_progress, magenta awaiting, yellow complete)
5. User with reduced motion preference sees static alternatives to animations

**Plans:** 1 plan
- [x] 07-dynamic-menu-bar-icon-01-PLAN.md — CompactStatusView 作为 MenuBarExtra label，动画和赛博朋克配色

**UI hint:** yes

**Completed:** 2026-04-03

---

#### Phase 8: Enhanced Status Detection

**Goal:** 提升状态检测准确率和响应速度

**Depends on:** Phase 7

**Requirements:** STATUS-01, STATUS-02, STATUS-03

**Success Criteria** (what must be TRUE):
1. System correctly identifies agent states (in_progress/awaiting_approval/complete) from window titles
2. System detects status changes within 3 seconds of actual state change
3. System shows reduced false positives in status detection compared to v1.0

**Plans:** 1 plan
- [x] 08-enhanced-status-detection-01-PLAN.md — 优先级检测顺序、错误状态处理、关键词精确匹配

**Completed:** 2026-04-03

---

#### Phase 9: Differentiated Sound System

**Goal:** 用户通过不同音效区分不同状态变化

**Depends on:** Phase 8

**Requirements:** SOUND-01, SOUND-02, SOUND-03

**Success Criteria** (what must be TRUE):
1. User hears different sound effect for each state (in_progress vs awaiting_approval vs complete)
2. Sound effects are silenced when system mute is on
3. User can enable/disable sound effects via preferences

**Plans:** 1 plan
- [x] 09-differentiated-sound-01-PLAN.md — SoundType 枚举、多音效文件、状态对应播放

**Completed:** 2026-04-03

---

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Data Layer Foundation | v1.0 | 1/1 | Complete | 2026-04-02 |
| 2. Main App Core | v1.0 | 1/1 | Complete | 2026-04-02 |
| 3. Dynamic Island Widget | v1.0 | 4/4 | Complete | 2026-04-02 |
| 4. Terminal Integration | v1.0 | 2/2 | Complete | 2026-04-03 |
| 5. Polish & Deployment | v1.0 | 1/2 | In progress | - |
| 6. Infrastructure Fixes | v2.0 | 2/2 | Complete | 2026-04-03 |
| 7. Dynamic Menu Bar Icon | v2.0 | 1/1 | Complete | 2026-04-03 |
| 8. Enhanced Status Detection | v2.0 | 1/1 | Complete | 2026-04-03 |
| 9. Differentiated Sound System | v2.0 | 1/1 | Complete | 2026-04-03 |

**Overall Progress:** 8/9 phases (v1.0 MVP + v2.0 kpbl 完成)

---

## Phase Ordering Rationale

### v1.0 MVP

**Phase 1 (Data Layer) first:** Shared container and state persistence are foundational. Without verified data flow between main app and widget, all subsequent work fails.

**Phase 2 (Main App Core) before Phase 3 (Widget):** Widget needs state feed from main app. Robust socket handling, state detection, and timeline reload triggers must work before UI can display anything useful.

**Phase 3 (Widget) before Phase 4 (Integration):** Terminal control is an enhancement to the core experience. The widget must render and update correctly before adding terminal integration complexity.

**Phase 4 (Integration) before Phase 5 (Polish):** All core features working before optimization and deployment preparation.

### v2.0 kpbl

**Phase 6 (Infrastructure Fixes) first:** Existing code has critical issues that would cause features to fail. The @ObservedObject singleton problem causes state loss, AVAudioSession misconfiguration causes sound failure in menu bar apps, and Accessibility permission absence causes silent window detection failures. These must be fixed before adding features.

**Phase 7 (Dynamic Icon) second:** Core v2.0 feature - dynamic menu bar icon showing status at a glance. Depends on Phase 6's state management fix.

**Phase 8 (Enhanced Detection) third:** Improved detection accuracy provides better data for dynamic icon. Complements Phase 7.

**Phase 9 (Sound System) fourth:** Differentiated sounds enhance user experience but depend on Phase 6's AVAudioSession fix. Less critical than visual status, so comes last.

---
*Roadmap created: 2026-04-02*
*Last updated: 2026-04-03 - v2.0 kpbl milestone complete (phases 6-9)*