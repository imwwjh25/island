# Phase 1: Data Layer Foundation - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

## Phase Boundary

Establish the shared data infrastructure that enables main app and widget extension to communicate and persist agent state reliably. This includes: connecting to Claude Code via local socket, parsing agent state messages, storing state in a shared container, and ensuring persistence across app lifecycle events.

## Implementation Decisions

### Socket Protocol Format
- **D-01:** JSON messages with explicit schema:
  ```json
  {
    "agent_id": "uuid",
    "status": "in_progress|complete|awaiting_approval",
    "terminal": "bundle_id:tab_id",
    "timestamp": "iso8601"
  }
  ```
  Keep schema simple and explicit. No nested structures beyond these required fields.

### Shared Data Structure
- **D-02:** Dictionary keyed by agent_id in UserDefaults:
  - Agent states as `[String: AgentState]` dictionary
  - Separate array for agent ordering (for display)
  - Clean schema: `{ "agents": [agent_id1, agent_id2, ...], "agentStates": { agent_id: {...}, ... } }`

### Connection Handling
- **D-03:** Exponential backoff reconnection strategy:
  - Initial delay: 1s, max delay: 30s, backoff factor: 2
  - Retry indefinitely (Claude Code may restart)
  - Heartbeat every 30s to detect dead connections
  - Graceful degradation: show "connection lost" state if unreachable

### Data Model Design
- **D-04:** Minimal fields per agent:
  - `id`: String (UUID)
  - `status`: Enum (in_progress, complete, awaiting_approval)
  - `terminalAppBundleId`: String (com.googlecode.iterm2, com.apple.Terminal)
  - `terminalTabId`: String (optional, if available)
  - `lastUpdated`: ISO8601 timestamp

### Claude's Discretion
- [None specified]

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Research Documents
- `.planning/research/STACK.md` — Technology stack: Swift 5.9+, SwiftUI, WidgetKit, Network framework (NWConnection), App Groups
- `.planning/research/ARCHITECTURE.md` — System architecture showing data flow from socket → Socket Monitor → State Manager → Widget Coordinator → Widget Center
- `.planning/research/PITFALLS.md` — Critical pitfalls: App Group misconfiguration (#2), socket robustness (#6), state persistence (#8)

### Requirements
- `.planning/REQUIREMENTS.md` — AGNT-01 (socket connection), AGNT-02 (state parsing), STMG-02 (persistence), STMG-03 (multi-agent display)

### Architecture Notes
- `.planning/research/ARCHITECTURE.md` §Socket Protocol Design — JSON format on TCP or Unix domain socket
- `.planning/research/ARCHITECTURE.md` §App Group + Shared Container — Must use identical group identifier, use `containerURL(forSecurityApplicationGroupIdentifier:)`

## Existing Code Insights

### Reusable Assets
- [None — greenfield project]

### Established Patterns
- [None — greenfield project]

### Integration Points
- Main app target: Socket Monitor entry point
- Widget extension: Shared container reader
- App Groups capability: Required on both targets with identical identifier

## Specific Ideas

No specific requirements — open to standard approaches.

## Deferred Ideas

None — discussion stayed within phase scope.

---

*Phase: 01-data-layer-foundation*
*Context gathered: 2026-04-02*