# Project State: Vibe Island

**Started:** 2026-04-02
**Current Status:** Planning complete, ready for Phase 1

---

## Project Reference

**Core Value:** Never lose track of which agent conversation needs your attention — see all agent states in one glance without switching terminals

**Current Focus:** Setting up data layer foundation (App Groups, socket monitoring, state persistence)

**Platform:** macOS 14+
**Agent Support:** Claude Code only (MVP)

---

## Current Position

**Phase:** 1
**Plan:** None created yet
**Status:** Not started
**Progress:** ▱▱▱▱▱ 0% complete

**Current Phase Goal:** Shared data infrastructure enables main app and widget to communicate and persist state reliably

---

## Performance Metrics

*No metrics yet - first phase not started*

---

## Accumulated Context

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

### Scope Boundaries

**MVP (v1):**
- Claude Code only
- iTerm2 and Terminal.app support
- Socket-based monitoring
- Core Dynamic Island UI (compact/expanded)
- Terminal tab jumping
- 8-bit sound effects
- Accessibility support

**Explicitly out of scope:**
- Other agents (Codex, OpenClaw) - defer to v2+
- WezTerm support - defer to v2+
- Activity history - defer to v2+
- Priority indicators - defer to v2+
- Custom notification system - use macOS native
- Chat interface in Dynamic Island - violates design principles
- Agent configuration UI - hardcoded for Claude Code in MVP

---

## Session Continuity

### Last Session

**Date:** 2026-04-02
**Work Completed:**
- Project initialized
- Research completed (HIGH confidence)
- Roadmap created (5 phases)
- Requirements defined (20 v1 requirements)

**Decisions Made:**
- Confirmed two-target architecture
- Adopted research-guided phase structure
- Granularity set to Standard

### Next Session

**Recommended starting point:** `/gsd:plan-phase 1`

**Context to carry forward:**
- Phase 1 requirements: AGNT-01, AGNT-02, STMG-02, STMG-03
- Research Phase 1 findings: App Groups, socket parsing, state persistence are well-documented
- Success criteria: 4 observable behaviors focused on data infrastructure

**Files to reference:**
- `.planning/ROADMAP.md` - Phase 1 details
- `.planning/REQUIREMENTS.md` - Full requirement list
- `.planning/research/SUMMARY.md` - Technical guidance for Phase 1

---

*State initialized: 2026-04-02*