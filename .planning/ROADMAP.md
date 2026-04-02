# Roadmap: Vibe Island

**Created:** 2026-04-02
**Granularity:** Standard
**Total Phases:** 5

## Overview

Vibe Island delivers real-time Claude Code agent status monitoring in the macOS Dynamic Island. The roadmap follows a dependency-driven approach: data layer foundation first, then main app core for monitoring, Dynamic Island UI for display, terminal integration for enhancement, and polish for deployment.

## Phases

- [x] **Phase 1: Data Layer Foundation** - App Groups, socket monitoring, and state persistence ✅
- [x] **Phase 2: Main App Core** - Background monitoring, sound effects, and state detection ✅
- [x] **Phase 3: Dynamic Island Widget** - UI rendering, visual prompts, and accessibility ✅
- [ ] **Phase 4: Terminal Integration** - Terminal tab jumping for iTerm2 and Terminal.app
- [ ] **Phase 5: Polish & Deployment** - Xcode project setup and DMG packaging for MVP

## Phase Details

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

**Note:** 由于 macOS 没有 iOS 风格的 Dynamic Island，使用 MenuBarExtra + Popover 作为替代方案。MenuBarExtra 不支持程序化展开 popover，使用视觉提示（闪烁、颜色变化、徽章）替代自动展开功能。

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
- [ ] 04-terminal-integration-01-PLAN.md — 创建 TerminalController 终端控制器（Wave 1）
- [ ] 04-terminal-integration-02-PLAN.md — 在 ExpandedDetailsView 中添加点击交互和错误反馈（Wave 2）

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
- [ ] 05-polish-deployment-01-PLAN.md — 创建 Xcode 项目和构建配置
- [ ] 05-polish-deployment-02-PLAN.md — 创建 DMG 安装包和功能验证

**Note:** 此阶段针对 MVP 简化，不包含 App Store 提交、性能分析、完整辅助功能测试。目标是生成可安装的应用包用于功能验证。

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Data Layer Foundation | 1/1 | Complete | 2026-04-02 |
| 2. Main App Core | 1/1 | Complete | 2026-04-02 |
| 3. Dynamic Island Widget | 4/4 | Complete | 2026-04-02 |
| 4. Terminal Integration | 0/2 | In planning | - |
| 5. Polish & Deployment | 0/2 | Planned | - |

**Overall Progress:** 3/5 phases complete

---

## Phase Ordering Rationale

**Phase 1 (Data Layer) first:** Shared container and state persistence are foundational. Without verified data flow between main app and widget, all subsequent work fails. This prevents App Group misconfiguration and unpersisted state issues.

**Phase 2 (Main App Core) before Phase 3 (Widget):** Widget needs state feed from main app. Robust socket handling, state detection, and timeline reload triggers must work before UI can display anything useful.

**Phase 3 (Widget) before Phase 4 (Integration):** Terminal control is an enhancement to the core experience. The widget must render and update correctly before adding terminal integration complexity.

**Phase 4 (Integration) before Phase 5 (Polish):** All core features working before optimization and deployment preparation.

---
*Roadmap created: 2026-04-02*
*Last updated: 2026-04-02 - Phase 5 planned*
