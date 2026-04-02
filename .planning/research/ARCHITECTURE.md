# Architecture Research: Dynamic Island App

**Last Updated:** 2026-04-02
**Domain:** macOS Dynamic Island Application Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         macOS System                             │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │   Claude Code  │  │   Terminal     │  │   Other Apps   │   │
│  │   (CLI)        │  │   (iTerm2)     │  │                │   │
│  └────────┬───────┘  └────────┬───────┘  └────────────────┘   │
│           │                   │                                 │
│           └─────────┬─────────┘                                 │
│                     ▼                                           │
│              ┌──────────────┐                                  │
│              │   Local      │                                  │
│              │   Socket     │                                  │
│              └──────┬───────┘                                  │
│                     │                                           │
└─────────────────────┼───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Vibe Island App                              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Main App Target                       │  │
│  │                                                           │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐        │  │
│  │  │ Socket     │  │ Process    │  │ Sound      │        │  │
│  │  │ Monitor    │  │ Monitor    │  │ Manager    │        │  │
│  │  └────────────┘  └────────────┘  └────────────┘        │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────┐   │  │
│  │  │           State Manager (Central)              │   │  │
│  │  │  - Agent state storage                          │   │  │
│  │  │  - State change events                         │   │  │
│  │  │  - Persistence (UserDefaults)                  │   │  │
│  │  └────────────────────────────────────────────────┘   │  │
│  │                          │                             │  │
│  │                          ▼                             │  │
│  │  ┌────────────────────────────────────────────────┐   │  │
│  │  │           Widget Coordinator                   │   │  │
│  │  │  - WidgetCenter.shared.reloadTimelines()       │   │  │
│  │  └────────────────────────────────────────────────┘   │  │
│  │                                                          │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐       │  │
│  │  │ Terminal   │  │ Preferences│  │ Menubar    │       │  │
│  │  │ Controller │  │ (if any)   │  │ Icon       │       │  │
│  │  └────────────┘  └────────────┘  └────────────┘       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                      │                                           │
│                      │ App Group / Shared Data                   │
│                      ▼                                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Widget Extension Target                     │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────┐   │  │
│  │  │           VibeIslandWidget                      │   │  │
│  │  │  - TimelineProvider implementation             │   │  │
│  │  │  - Dynamic Island view (compact/expanded)      │   │  │
│  │  │  - Agent card components                        │   │  │
│  │  └────────────────────────────────────────────────┘   │  │
│  │                                                           │  │
│  │  ┌────────────────────────────────────────────────┐   │  │
│  │  │           UI Views (SwiftUI)                    │   │  │
│  │  │  - CompactView                                │   │  │
│  │  │  - ExpandedView                               │   │  │
│  │  │  - AgentCardView                              │   │  │
│  │  │  - StatusIndicatorView                        │   │  │
│  │  └────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                      │                                           │
│                      ▼                                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │             macOS Dynamic Island (System)                │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Boundaries

### Main App Target

**Responsibilities:**
- Background monitoring of Claude Code via socket
- State management and persistence
- Sound playback
- Terminal control (tab jumping)
- Triggering widget timeline updates

**External Interfaces:**
- Local socket connection (input from Claude Code)
- Widget Center API (output to widget)
- AppKit (terminal control, accessibility)
- AVFoundation (sound)

### Widget Extension Target

**Responsibilities:**
- Rendering Dynamic Island UI
- Providing data to WidgetKit via TimelineProvider
- Handling user interactions (tap to open app)

**External Interfaces:**
- Shared container (input from main app state)
- WidgetKit (output to system)

### Data Flow

```
Claude Code ──[Socket]──> Socket Monitor ──> State Manager
                                                       │
                                                       ├──> [UserDefaults] ──> Shared Container
                                                       │
                                                       └──> Widget Coordinator ──> Widget Center
                                                                              │
                                                                              ▼
                                                                  Widget Extension
                                                                              │
                                                                              ▼
                                                                  Dynamic Island UI
```

### Build Order (Dependencies)

1. **Phase 1: Data Layer** (Foundation)
   - Socket Monitor
   - State Manager
   - Shared Data Models

2. **Phase 2: Main App Core**
   - Sound Manager
   - Process Monitor
   - Widget Coordinator

3. **Phase 3: Widget Extension**
   - TimelineProvider implementation
   - Basic UI components
   - Dynamic Island views

4. **Phase 4: Integration**
   - Terminal Controller
   - State persistence
   - End-to-end communication

## Key Architectural Decisions

### App Group + Shared Container
- **Why**: Main app and widget extension are separate processes
- **Implementation**: Enable App Groups capability, use `containerURL(forSecurityApplicationGroupIdentifier:)`
- **Data**: Shared UserDefaults + file-based persistence for larger state

### Widget as Primary UI
- **Why**: Dynamic Island is the core product, main app may never be visible
- **Implication**: Main app is primarily a background service
- **Fallback**: Small preferences window if configuration needed

### State-Driven Updates
- **Why**: WidgetKit is timeline-based, not event-driven
- **Implementation**: Main app maintains state, triggers timeline reload on changes
- **Challenge**: Balancing real-time needs with WidgetKit's update intervals

### Socket Protocol Design
- **Why**: Custom protocol needed for Claude Code communication
- **Format**: JSON messages over TCP or Unix domain socket
- **Messages**: `{"agent_id": "...", "status": "in_progress|complete|awaiting", "terminal": "..."}`

## Performance Considerations

### Low Resource Usage
- Main app must be lightweight (always running)
- Widget should update efficiently (timeline caching)
- Socket monitoring should be async/non-blocking

### Update Frequency
- WidgetKit updates are not instantaneous
- State changes should batch to avoid excessive timeline reloads
- Consider `WidgetCenter.shared.reloadTimelines()` throttling

### Memory Management
- Shared container should avoid large data transfer
- Sound assets should be lazy-loaded
- Socket connections should be properly closed

## Security Considerations

### Local Socket Only
- No network communication beyond localhost
- Unix domain socket preferred (no port binding needed)

### Minimal Permissions
- Only necessary macOS entitlements (App Groups)
- No Accessibility unless absolutely required (avoid if possible)
- No File System access beyond app container

### Privacy
- No capture or display of terminal content
- No transmission of user data
- Agent states are local-only

## Testing Strategy

### Unit Tests
- Socket Monitor (mock socket, state updates)
- State Manager (state transitions, persistence)
- Sound Manager (playback triggers)

### Integration Tests
- Widget timeline updates from state changes
- Socket protocol parsing
- Shared container data flow

### UI Tests
- Dynamic Island compact/expanded states
- Tap interactions
- Auto-expand behavior

---
*Research completed: 2026-04-02*