# Phase 1: Data Layer Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-02
**Phase:** 1-data-layer-foundation
**Mode:** auto
**Areas discussed:** Socket protocol format, Shared data structure, Connection handling, Data model design

---

## Socket Protocol Format

| Option | Description | Selected |
|--------|-------------|----------|
| JSON with explicit schema | Simple, explicit JSON with agent_id, status, terminal, timestamp | ✓ |
| Binary protocol | More efficient, harder to debug | |
| Protocol Buffers | Cross-language, overkill for local socket | |

**User's choice:** [auto] JSON with explicit schema
**Notes:** Chose JSON for simplicity and explicit schema. Keep it simple and explicit with no nested structures beyond required fields.

---

## Shared Data Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Dictionary keyed by agent_id | `[String: AgentState]` with separate ordering array | ✓ |
| Flat array | All agents in one array, unordered | |
| Indexed approach | Array with indices for fast lookup | |

**User's choice:** [auto] Dictionary keyed by agent_id
**Notes:** Clean schema with separate array for ordering: `{ "agents": [agent_id1, ...], "agentStates": { agent_id: {...}, ... } }`

---

## Connection Handling

| Option | Description | Selected |
|--------|-------------|----------|
| Exponential backoff retry | 1s → 30s max, indefinite retry, 30s heartbeat | ✓ |
| Fixed interval retry | Simple, but may flood retries | |
| Fail fast | Give up quickly, requires manual reconnect | |

**User's choice:** [auto] Exponential backoff retry
**Notes:** Indefinite retry since Claude Code may restart. Graceful degradation with "connection lost" state.

---

## Data Model Design

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal fields | id, status, terminalAppBundleId, terminalTabId, lastUpdated | ✓ |
| Rich metadata | Include more context like task description, duration | |
| Nested terminal info | Terminal as separate object type | |

**User's choice:** [auto] Minimal fields
**Notes:** Keep it lean for MVP. Status as enum: in_progress, complete, awaiting_approval.

---

## Claude's Discretion

None — all areas were explicitly decided.

## Deferred Ideas

None — discussion stayed within phase scope.