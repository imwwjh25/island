# Vibe Island

## What This Is

Vibe Island is a macOS Dynamic Island app that displays real-time status of Claude Code agents running in parallel. It shows all your active agent conversations in one glance, expanding automatically when you need to take action or a task completes.

## Core Value

Never lose track of which agent conversation needs your attention — see all agent states in one glance without switching terminals.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Monitor Claude Code agent status via local socket
- [ ] Display status in Dynamic Island (in progress / complete / awaiting approval)
- [ ] Auto-expand Dynamic Island when agent needs approval or completes
- [ ] Click card to jump to corresponding terminal tab
- [ ] 8-bit pixel game sound effects for all state changes

### Out of Scope

- Other agents (Codex, OpenClaw, etc.) — defer to v2+ after validating with Claude Code
- Agent configuration UI — hardcoded for Claude Code in MVP
- Terminal app integration beyond tab jumping — custom terminal UI not in scope

## Context

User runs 5-10 Claude Code conversations in parallel during Vibe Coding sessions. Switching between terminals causes context loss — forgets which conversations are still running, which need approval, which are done. Human context window is overloaded.

Dynamic Island provides an elegant UI pattern: shows background task state without interrupting foreground work, only expands when attention is needed, enables lightweight interaction without app switching, adds a sense of presence/companionship.

## Constraints

- **Platform**: macOS only (Dynamic Island feature requires macOS 14+)
- **Agent**: Claude Code only (MVP scope)
- **Input**: Socket-based monitoring (preferred over log parsing)
- **Terminal**: iTerm2 / WezTerm / Terminal.app (support tab jumping)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Socket-based monitoring | Real-time, reliable state detection vs brittle log parsing | — Pending |
| Include sound effects in MVP | Core to the "Vibe" experience, not a polish item | — Pending |
| Claude Code only | Validate core concept before expanding to other agents | — Pending |

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
*Last updated: 2026-04-02 after initialization*