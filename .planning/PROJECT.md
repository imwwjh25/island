# Vibe Island

## What This Is

Vibe Island is a macOS Dynamic Island app that displays real-time status of Claude Code agents running in parallel. It shows all your active agent conversations in one glance, expanding automatically when you need to take action or a task completes.

## Core Value

Never lose track of which agent conversation needs your attention — see all agent states in one glance without switching terminals.

## Requirements

### Validated

- [x] Monitor Claude Code agent status via local socket - Validated in Phase 1
- [x] Display status in MenuBarExtra (in progress / complete / awaiting approval) - Validated in Phase 3
- [x] Visual prompts when agent needs approval or completes - Validated in Phase 3
- [x] 8-bit pixel game sound effects for all state changes - Validated in Phase 2

### Active

- [ ] Click agent card to jump to corresponding terminal tab - Phase 4

### Out of Scope

- Other agents (Codex, OpenClaw, etc.) — defer to v2+ after validating with Claude Code
- Agent configuration UI — hardcoded for Claude Code in MVP
- Terminal app integration beyond tab jumping — custom terminal UI not in scope

## Context

User runs 5-10 Claude Code conversations in parallel during Vibe Coding sessions. Switching between terminals causes context loss — forgets which conversations are still running, which need approval, which are done. Human context window is overloaded.

MenuBarExtra provides an elegant UI pattern: shows background task state without interrupting foreground work, only provides visual cues when attention is needed (blinking, color changes), enables lightweight interaction without app switching, adds a sense of presence/companionship.

**Technical Reality:** macOS doesn't support iOS-style Dynamic Island (requires specific camera hardware). MenuBarExtra with expandable popover provides the closest equivalent experience.

## Constraints

- **Platform**: macOS only (Dynamic Island feature requires macOS 14+)
- **Agent**: Claude Code only (MVP scope)
- **Input**: Socket-based monitoring (preferred over log parsing)
- **Terminal**: iTerm2 / WezTerm / Terminal.app (support tab jumping)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Socket-based monitoring | Real-time, reliable state detection vs brittle log parsing | ✅ Implemented in Phase 1 |
| Include sound effects in MVP | Core to the "Vibe" experience, not a polish item | ✅ Implemented in Phase 2 |
| Claude Code only | Validate core concept before expanding to other agents | ✅ MVP scope confirmed |
| MenuBarExtra over Dynamic Island | macOS doesn't support iOS Dynamic Island; MenuBarExtra is native equivalent | ✅ Implemented in Phase 3 |
| Visual prompts over auto-expand | MenuBarExtra doesn't support programmatic popover expansion | ✅ Implemented in Phase 3 |
| Semantic colors for accessibility | Automatic light/dark mode adaptation, Apple compliance | ✅ Implemented in Phase 3 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-02 after Phase 3 completion*