# Roadmap: Vibe Island

**Created:** 2026-04-02
**Granularity:** Standard
**Total Phases:** 5

## Overview

Vibe Island delivers real-time Claude Code agent status monitoring in the macOS Dynamic Island. The roadmap follows a dependency-driven approach: data layer foundation first, then main app core for monitoring, Dynamic Island UI for display, terminal integration for enhancement, and polish for deployment.

## Phases

- [ ] **Phase 1: Data Layer Foundation** - App Groups, socket monitoring, and state persistence
- [ ] **Phase 2: Main App Core** - Background monitoring, sound effects, and state detection
- [ ] **Phase 3: Dynamic Island Widget** - UI rendering, auto-expansion, and accessibility
- [ ] **Phase 4: Terminal Integration** - Terminal tab jumping for iTerm2 and Terminal.app
- [ ] **Phase 5: Polish & Deployment** - Performance, App Store preparation, final testing

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

**Plans:** TBD

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

**Plans:** TBD

---

### Phase 3: Dynamic Island Widget

**Goal:** Users view and interact with agent states in Dynamic Island

**Depends on:** Phase 2

**Requirements:** DIUI-01, DIUI-02, DIUI-03, DIUI-04, STMG-03, CORE-01, CORE-02, ACCS-01, ACCS-02, ACCS-03

**Success Criteria** (what must be TRUE):
1. User sees compact state with agent count and status summary
2. User can tap Dynamic Island to expand to detailed view
3. Dynamic Island automatically expands when agent needs approval
4. Dynamic Island automatically expands when agent completes
5. User sees smooth animations between compact and expanded states
6. User can tap background to collapse expanded view
7. VoiceOver announces Dynamic Island content correctly
8. Dynamic Island UI adapts to system appearance (light/dark mode)
9. Dynamic Island UI respects reduced motion accessibility setting

**Plans:** TBD

**UI hint:** yes

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

**Plans:** TBD

---

### Phase 5: Polish & Deployment

**Goal:** App is performant, accessible, and ready for App Store submission

**Depends on:** Phase 4

**Requirements:** (None - final polish phase)

**Success Criteria** (what must be TRUE):
1. App has no memory leaks (verified with Instruments profiling)
2. App meets App Store accessibility requirements
3. App Store assets (screenshots, metadata) are complete
4. macOS 14+ requirement is correctly specified in deployment target
5. End-to-end testing confirms all features work correctly

**Plans:** TBD

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Data Layer Foundation | 0/0 | Not started | - |
| 2. Main App Core | 0/0 | Not started | - |
| 3. Dynamic Island Widget | 0/0 | Not started | - |
| 4. Terminal Integration | 0/0 | Not started | - |
| 5. Polish & Deployment | 0/0 | Not started | - |

**Overall Progress:** 0/5 phases complete

---

## Phase Ordering Rationale

**Phase 1 (Data Layer) first:** Shared container and state persistence are foundational. Without verified data flow between main app and widget, all subsequent work fails. This prevents App Group misconfiguration and unpersisted state issues.

**Phase 2 (Main App Core) before Phase 3 (Widget):** Widget needs state feed from main app. Robust socket handling, state detection, and timeline reload triggers must work before UI can display anything useful.

**Phase 3 (Widget) before Phase 4 (Integration):** Terminal control is an enhancement to the core experience. The widget must render and update correctly before adding terminal integration complexity.

**Phase 4 (Integration) before Phase 5 (Polish):** All core features working before optimization and deployment preparation.

---

*Roadmap created: 2026-04-02*