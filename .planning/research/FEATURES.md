# Features Research: Dynamic Island Apps

**Last Updated:** 2026-04-02
**Domain:** macOS Dynamic Island Applications

## Table Stakes

Users expect these features — without them, the app feels broken or incomplete.

### Core UI States
- **Compact State** - Default collapsed view showing minimal status
- **Expanded State** - Tap to reveal more details and controls
- **Smooth Animations** - Fluid transitions between states (Apple's 0.25s timing)
- **High Contrast** - Readable text in both compact and expanded states
- **System-Consistent Styling** - Matches macOS design language

### State Management
- **Real-time Updates** - Status reflects actual current state, not stale
- **Persistent State** - Survives app backgrounding/termination
- **Error Handling** - Graceful degradation when data unavailable

### Interaction
- **Tap to Expand** - Standard gesture for revealing details
- **Tap Background to Collapse** - Dismiss expanded state
- **Visual Feedback** - Response to user actions

### Integration
- **Main App Opens** - Tapping opens the main application
- **Bundle ID Identification** - Shows which app owns the activity
- **Icon/Thumbnail** - Visual identification of activity source

## Differentiators

Features that create competitive advantage or unique value.

### Advanced Interactions
- **Auto-Expand on State Change** - Automatically expands when user attention needed (e.g., waiting for approval)
- **Multiple Concurrent Activities** - Display multiple agent states simultaneously
- **Custom Sound Effects** - Unique audio feedback for different state transitions
- **Terminal Tab Jumping** - Direct navigation to specific terminal tab

### Multi-Agent Support
- **Agent Aggregation** - Show all active agents in one view
- **Status Categorization** - Color-coded or icon-based status indicators
- **Agent-Specific Details** - Different information per agent type

### Enhanced UX
- **Activity History** - Quick access to recent completed tasks
- **Priority Indicators** - Visual distinction for urgent tasks
- **Custom Animation Curves** - Unique feel vs standard Apple animations

## Anti-Features

Features to deliberately avoid — complexity without sufficient value.

### Over-Engineering
- **Full-Screen App Widget** - Dynamic Island should stay in the island
- **Custom Notification System** - Use macOS native notifications instead
- **Chat Interface in Island** - Too cramped, violates Apple's compact design principles
- **Voice Controls** - Unnecessary complexity for MVP

### Privacy Violations
- **Screen Capture** - Never capture or display user screen content
- **Terminal Content Display** - Status only, not actual terminal output
- **Agent Response Content** - Show state only, not private content

### System Interference
- **Always-Top Overlay** - Dynamic Island handles placement naturally
- **Global Keyboard Shortcuts** - Let users configure if needed
- **Process Injection** - Never modify other applications

## Feature Complexity Assessment

| Feature | Complexity | Dependencies | MVP Priority |
|---------|------------|--------------|--------------|
| Compact State | Low | WidgetKit, SwiftUI | Required |
| Expanded State | Low | WidgetKit, SwiftUI | Required |
| Tap Interactions | Low | WidgetKit | Required |
| Real-time Updates | Medium | Socket monitoring, TimelineProvider | Required |
| Auto-Expand | Medium | State change detection, activity triggers | High |
| Sound Effects | Low | AVFoundation, audio assets | High (per user) |
| Terminal Jump | High | AppKit, AppleScript, Accessibility | High |
| Multi-Agent Display | Medium | Data model, widget configuration | Required |
| Activity History | Medium | Persistence, data model | Low |

## Dependencies Between Features

1. **Real-time Updates** required for:
   - Auto-Expand (must know when state changes)
   - Status Display (must reflect actual state)

2. **Terminal Jump** requires:
   - Agent identification (which agent = which terminal)
   - Terminal app detection (iTerm2 vs Terminal.app)

3. **Sound Effects** requires:
   - State change detection (triggers to play sounds)
   - Sound asset management

4. **Auto-Expand** requires:
   - State change detection
   - Activity API for programmatic expansion

## Vibe Island-Specific Considerations

This is a **system utility** app, not a typical content app:
- Main app may be invisible (menubar-only or background-only)
- Core value is in the Dynamic Island widget
- Background monitoring is essential
- Low resource usage critical (always running)
- Minimal UI interaction (mostly informational display)

---
*Research completed: 2026-04-02*