# Requirements: Vibe Island

**Defined:** 2026-04-02
**Core Value:** Never lose track of which agent conversation needs your attention — see all agent states in one glance without switching terminals

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Dynamic Island UI

- [x] **DIUI-01**: User sees compact state with agent count and status summary
- [x] **DIUI-02**: User can tap Dynamic Island to expand to detailed view
- [x] **DIUI-03**: User sees smooth animations between compact and expanded states
- [x] **DIUI-04**: User can tap background to collapse expanded view

### State Management

- [x] **STMG-01**: Agent states reflect actual Claude Code status (not stale data)
- [x] **STMG-02**: Agent states persist across app backgrounding and termination
- [x] **STMG-03**: Multiple active Claude Code agents display in one Dynamic Island view

### Agent Monitoring

- [x] **AGNT-01**: App connects to Claude Code via local socket
- [x] **AGNT-02**: App parses agent states: in_progress, complete, awaiting_approval
- [x] **AGNT-03**: App detects when agent status changes

### Core Features

- [x] **CORE-01**: Dynamic Island automatically expands when agent needs approval
- [x] **CORE-02**: Dynamic Island automatically expands when agent completes
- [ ] **CORE-03**: User can click agent card to jump to corresponding terminal tab (iTerm2)
- [ ] **CORE-04**: User can click agent card to jump to corresponding terminal tab (Terminal.app)
- [x] **CORE-05**: App plays 8-bit pixel game sound effect when agent changes to in_progress
- [x] **CORE-06**: App plays 8-bit pixel game sound effect when agent changes to complete
- [x] **CORE-07**: App plays 8-bit pixel game sound effect when agent changes to awaiting_approval
- [x] **CORE-08**: Sound effects respect system mute state

### Accessibility

- [x] **ACCS-01**: VoiceOver announces Dynamic Island content correctly
- [x] **ACCS-02**: Dynamic Island UI adapts to system appearance (light/dark mode)
- [x] **ACCS-03**: Dynamic Island UI respects reduced motion accessibility setting

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Enhanced UX

- **ENH-01**: User can view activity history of recently completed agents
- **ENH-02**: User sees priority indicators for urgent tasks
- **ENH-03**: Terminal tab jumping supports WezTerm
- **ENH-04**: User can toggle sound effects on/off via preferences

### Additional Agents

- **AGXT-01**: App supports monitoring Codex agents
- **AGXT-02**: App supports monitoring OpenClaw agents

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Terminal content display | Privacy concern — status only, not actual terminal output or agent responses |
| Other agents (Codex, OpenClaw) | MVP scope — validate with Claude Code first, expand in v2+ |
| Activity history | Defer to v2+ — nice to have but not essential for MVP validation |
| Priority indicators | Defer to v2+ — nice to have but not essential for MVP validation |
| WezTerm terminal support | Defer to v2+ — iTerm2 and Terminal.app sufficient for MVP validation |
| Custom notification system | Use macOS native notifications instead |
| Chat interface in Dynamic Island | Too cramped, violates Apple's compact design principles |
| Agent configuration UI | Hardcoded for Claude Code in MVP — defer to v2+ |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DIUI-01 | Phase 3 | Complete |
| DIUI-02 | Phase 3 | Complete |
| DIUI-03 | Phase 3 | Complete |
| DIUI-04 | Phase 3 | Complete |
| STMG-01 | Phase 2 | Complete |
| STMG-02 | Phase 1 | Complete |
| STMG-03 | Phase 3 | Complete |
| AGNT-01 | Phase 1 | Complete |
| AGNT-02 | Phase 1 | Complete |
| AGNT-03 | Phase 2 | Complete |
| CORE-01 | Phase 3 | Complete |
| CORE-02 | Phase 3 | Complete |
| CORE-03 | Phase 4 | Pending |
| CORE-04 | Phase 4 | Pending |
| CORE-05 | Phase 2 | Complete |
| CORE-06 | Phase 2 | Complete |
| CORE-07 | Phase 2 | Complete |
| CORE-08 | Phase 2 | Complete |
| ACCS-01 | Phase 3 | Complete |
| ACCS-02 | Phase 3 | Complete |
| ACCS-03 | Phase 3 | Complete |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0 ✓
- Completed: 18/20 (90%)

**Phase Distribution:**
- Phase 1: 4 requirements (Data Layer Foundation) - Complete ✓
- Phase 2: 6 requirements (Main App Core) - Complete ✓
- Phase 3: 10 requirements (Dynamic Island Widget) - Complete ✓
- Phase 4: 2 requirements (Terminal Integration) - Pending
- Phase 5: 0 requirements (Polish & Deployment)

---
*Requirements defined: 2026-04-02*
*Last updated: 2026-04-02 after Phase 3 completion*