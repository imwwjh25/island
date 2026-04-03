# Feature Research: Dynamic Menu Bar Status Indicators

**Project:** Vibe Island (kpbl milestone)
**Domain:** macOS Menu Bar Dynamic UI + Status Detection
**Researched:** 2026-04-03

## Context

This is a **subsequent milestone** building on existing v1.0 features. The app already has:
- `MenuBarExtra` with static "sparkles" icon
- `ProcessMonitor` detecting Claude Code processes via sysctl
- `WindowMonitor` parsing window titles via Accessibility API
- `StateManager` managing agent states (inProgress/complete/awaitingApproval)
- `ExpandedDetailsView` showing agent cards
- `CompactStatusView` with status dots and badge (commercial version)
- `SoundManager` playing single state_update.aiff on changes

**NEW features for v2.0 kpbl milestone:**
1. Dynamic menu bar icon (status dots + count badge integrated into MenuBarExtra)
2. Blinking/flashing animation for important state changes
3. Enhanced status detection (more accurate identification)
4. Differentiated sound effects (different sounds per status type)

---

## Table Stakes

Features users expect. Missing these makes the app feel incomplete.

### Dynamic Menu Bar Indicator

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Status indicator visible** | Users glance at menu bar for background task status | Low | MenuBarExtra must show state |
| **Real-time updates** | Status should reflect current reality, not stale data | Medium | 3s polling interval acceptable |
| **Count badge** | Know how many agents active without clicking | Low | Number overlay on icon |
| **Color coding** | Distinguish states by color (blue/green/orange) | Low | Semantic colors for accessibility |
| **Click to expand** | Standard MenuBarExtra interaction pattern | Low | Already implemented |

**Gap analysis for existing implementation:**
- `VibeIslandMenuBar.swift` uses `MenuBarExtra("Vibe Island", systemImage: "sparkles")` - STATIC icon
- `CompactStatusView.swift` (commercial) has status dots + badge logic - but NOT integrated into MenuBarExtra label
- Need to replace `systemImage:` with dynamic `label:` using CompactStatusView as the label content

### Status Detection Accuracy

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Correct identification** | Wrong status breaks user trust | High | Heuristics are fragile |
| **Timely detection** | 3-second max latency acceptable | Medium | Current 2-3s interval |
| **State transitions detected** | Know when status CHANGES, not just current state | Medium | StateManager tracks lastStates |
| **Agent-to-terminal correlation** | Know which terminal tab for each agent | High | Terminal bundleId + tabId tracking |

**Current detection methods:**
1. `ProcessMonitor` - sysctl to find node/claude processes (PID-based, robust)
2. `WindowMonitor` - Accessibility API for window title parsing (heuristic, fragile)

**Keywords detected by WindowMonitor.detectStatus():**
- `awaitingApproval`: "awaiting", "approval", "waiting", "confirm", "y/n", "?"
- `complete`: "complete", "done", "finished", "success"
- `inProgress`: default fallback

**Gap:** Current heuristics may misidentify states. Claude Code's actual terminal output patterns need validation.

### Sound Effects

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Sound on state change** | Audio feedback for background events | Low | SoundManager exists |
| **System mute respect** | Don't play when system muted | Medium | AppleScript volume check |
| **User toggle** | Ability to disable sounds | Low | isSoundEnabled UserDefaults |

**Gap:** Single sound file (`state_update.aiff`) for all transitions. Users can't distinguish states by sound.

---

## Differentiators

Features that set Vibe Island apart from basic menu bar apps.

### Visual Attention Capture

| Feature | Value Proposition | Complexity | Existing? |
|---------|-------------------|------------|-----------|
| **Blinking animation** | Grab attention when agent needs approval or completes | Medium | Partial (hasNewImportantState flag exists) |
| **Scale pulse effect** | Visual emphasis on status change | Low | Implemented (scaleEffect 1.2) |
| **Shadow glow** | Highlight important state with colored shadow | Low | Implemented (shadow with accentColor) |
| **"!" badge overlay** | Exclamation mark for attention-needed states | Low | Implemented (Text("!") badge) |

**Current CompactStatusView animation:**
```swift
.animation(
    reducedMotion ? .none : Animation.easeInOut(duration: 0.5).repeatCount(3),
    value: isBlinking
)
```

**Enhancement needed:** Animation triggers via NotificationCenter `.showVisualPrompt` but integration with MenuBarExtra label needs verification.

### Enhanced Terminal Integration

| Feature | Value Proposition | Complexity | Existing? |
|---------|-------------------|------------|-----------|
| **Click-to-jump** | One click to agent's terminal tab | Medium | TerminalController exists |
| **Tab ID extraction** | Know exact tab to activate | High | Heuristic from title parsing |
| **Multi-terminal support** | iTerm2 + Terminal.app | Medium | Both bundle IDs tracked |
| **Jump error handling** | Clear feedback when jump fails | Low | Alert dialog implemented |

**Gap:** Terminal tabId extraction relies on `extractTabInfo()` parsing window title separators. This is fragile - tab IDs may not match actual terminal session IDs.

### Status Types Beyond Basic

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Error state** | Know when agent encounters issues | Medium | No current detection |
| **Idle state** | Distinguish "waiting for input" vs "processing" | Low | No detection, defaults to inProgress |
| **Thinking indicator** | Show agent is processing, not idle | Low | Could detect from title patterns |

---

## Anti-Features

Features to explicitly NOT build for v2.0.

### Over-Engineering

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Socket protocol detection** | Claude Code CLI doesn't expose socket; complex to implement | Continue using window title + process detection |
| **AI-powered title parsing** | Overkill for simple status detection, adds latency | Use regex keyword matching with validation |
| **Custom notification center** | macOS has native notifications; reinventing is wasteful | Use system notifications if needed (v3+) |
| **Full terminal content capture** | Privacy concern, Accessibility limitations, overkill | Status only, never capture content |

### Scope Creep

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Multi-agent support (Codex)** | Validate concept with Claude Code first; defer expansion | v3+ roadmap item |
| **Agent configuration UI** | MVP is hardcoded for Claude Code; personal use app | Accept hardcoded config for kpbl |
| **Activity history** | Nice-to-have, not critical for milestone | Defer to v3+ |
| **WezTerm support** | Smaller user base than iTerm2/Terminal.app | Defer to v3+ |

---

## Feature Dependencies

```
Dynamic Menu Bar Icon
    └── CompactStatusView integration
        ├── StateManager @Published agentStates
        ├── MenuBarExtra label: parameter
        └── Animation triggers (NotificationCenter)

Enhanced Status Detection
    ├── WindowMonitor (Accessibility API)
    ├── ProcessMonitor (sysctl)
    └── StateManager state aggregation
        └── SoundManager triggers

Differentiated Sound Effects
    ├── SoundManager enhancement
        ├── Multiple sound files
        ├── Status-based selection
        └── AVAudioPlayer instances
```

---

## Terminal Window Title Analysis

### Claude Code Observable Patterns

Based on Claude Code CLI behavior analysis:

| State | Terminal Window Title Pattern | Detection Method | Confidence |
|-------|------------------------------|------------------|------------|
| **Running/Active** | `claude > ...` or `claude@dir:~$` | Prompt pattern match | HIGH |
| **Awaiting Approval** | `Awaiting your approval...`, `y/n?` | Keyword match | MEDIUM |
| **Complete** | `Complete!`, `Done`, `Task finished` | Keyword match | MEDIUM |
| **Thinking** | `Thinking...`, `Processing...` | Keyword match | LOW (may not appear) |
| **Error** | `Error:`, `Failed:`, `Unable to` | Keyword match | LOW (internal, may not title) |

### Detection Recommendations

1. **Add exclusions:** `?` alone is too broad - "Thinking..." contains `?` pattern ambiguity
2. **Priority order:** Check awaiting BEFORE complete (complete patterns may overlap)
3. **Negative keywords:** If title contains "error" but also "waiting", prioritize error
4. **Session ID extraction:** Claude Code may expose session ID in title - parse for agent correlation

**Recommended detection priority:**
```
1. Error patterns (highest priority)
2. Awaiting approval patterns
3. Complete patterns
4. Default to inProgress
```

---

## Menu Bar Animation Research

### Standard Patterns in Popular Apps

| App | Status Indicator | Animation Pattern |
|-----|-------------------|-------------------|
| **Dropbox** | Sync activity | Rotating dots during sync |
| **Slack** | Notification badge | Pulse on new message, static otherwise |
| **Discord** | Notification badge | Badge appears with bounce, then static |
| **iTerm2** | Shell indicator | Static badge, no animation |

### Recommended Animation for Vibe Island

| State Transition | Animation | Duration | Accessibility |
|------------------|-----------|----------|---------------|
| **New agent awaiting** | Pulse + shadow glow + scale 1.2 | 3 pulses, 0.5s each | Reduce motion: instant scale |
| **Agent completes** | Scale bounce + green glow | 2 pulses, 0.3s each | Reduce motion: instant color |
| **Normal state** | Static | None | N/A |
| **State transition fade** | Opacity transition | 0.25s | Reduce motion: instant |

**Implementation note:** SwiftUI `.animation()` with `accessibilityReduceMotion` environment check:
```swift
@Environment(\.accessibilityReduceMotion) private var reducedMotion

.animation(
    reducedMotion ? .none : Animation.easeInOut(duration: 0.5).repeatCount(3),
    value: isBlinking
)
```

---

## Sound Effect Differentiation

### 8-bit Pixel Game Sound Categories

| State | Sound Type | Example | Character |
|-------|------------|---------|-----------|
| **Start (in_progress)** | Coin/pickup chime | Mario coin | Positive, short |
| **Awaiting approval** | Alert/question tone | Puzzle tone | Asks attention |
| **Complete** | Victory/celebration | Level complete | Satisfying, longer |

### Implementation Approach

```swift
// Enhanced SoundManager:
enum SoundType: String {
    case inProgress = "start"
    case awaitingApproval = "awaiting"
    case complete = "complete"
}

func playStateChangeSound(for status: AgentStatus) {
    let soundFile = soundFileForStatus(status)
    playSound(soundFile)
}

private func soundFileForStatus(_ status: AgentStatus) -> String {
    switch status {
    case .inProgress: return "start.wav"
    case .awaitingApproval: return "awaiting.wav"
    case .complete: return "complete.wav"
    }
}
```

### Sound File Requirements

| File | Duration | Character | Priority |
|------|----------|-----------|----------|
| start.wav | 0.3-0.5s | Positive chirp | Medium (happens frequently) |
| awaiting.wav | 0.4-0.6s | Alert tone, question feel | HIGH (needs attention) |
| complete.wav | 0.5-0.8s | Victory fanfare | HIGH (satisfaction moment) |

---

## Complexity Assessment

| Feature | Complexity | Effort Estimate | Risk Level |
|---------|------------|-----------------|------------|
| Dynamic icon integration | Low | 1-2 hours | Low (infrastructure exists) |
| Sound differentiation | Low | 2-3 hours | Low (SoundManager exists) |
| Enhanced keyword detection | Medium | 4-6 hours | Medium (needs real-world testing) |
| Animation polish | Medium | 2-4 hours | Low (SwiftUI patterns known) |
| Process-to-tab correlation | High | 8-12 hours | HIGH (fragile heuristics) |

---

## MVP Recommendation for v2.0 kpbl

**Prioritize:**
1. **Dynamic MenuBarExtra icon** - Replace systemImage with CompactStatusView label
2. **Differentiated sounds** - 3 sound files for different states
3. **Animation polish** - Ensure blinking triggers correctly on MenuBarExtra label

**Defer:**
- **Enhanced detection patterns** - Validate with real Claude Code sessions first
- **Error state detection** - Need to observe actual error output patterns
- **Tab ID accuracy improvement** - Complex, may need different approach

---

## Open Questions

1. **MenuBarExtra label parameter:** Does MenuBarExtra accept arbitrary SwiftUI views as `label:`? Need to test if CompactStatusView can be used directly.

2. **Claude Code actual output patterns:** What exactly appears in terminal window during awaiting, complete, error states? Need hands-on testing.

3. **Sound file format compatibility:** Does AVAudioPlayer handle WAV equally well as AIFF? Should work, but verify.

4. **Animation in MenuBarExtra context:** Do animations work reliably inside MenuBarExtra label? May have performance constraints.

---

## Sources

### Primary (HIGH confidence)
- Existing VibeIsland codebase - CompactStatusView, SoundManager, StateManager
- Apple Documentation - MenuBarExtra API, SwiftUI animation
- Apple Documentation - AVAudioPlayer, AVFoundation

### Secondary (MEDIUM confidence)
- iTerm2 AppleScript dictionary - Tab identification patterns
- macOS Menu Bar design patterns - Standard indicator behaviors

### Tertiary (LOW confidence)
- WebSearch results (limited) - Terminal window title patterns
- Community discussions - Claude Code observable behaviors

---
*Research completed: 2026-04-03*
*Ready for v2.0 kpbl milestone planning*