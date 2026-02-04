<!-- telos-metadata
id: L2:contract:component-tab-bar
level: 2
title: Tab Bar Component
parent: L3:experience:session-management
children: []
-->

# L2: Tab Bar Component

## Overview

The Tab Bar displays and manages multiple terminal session tabs, showing
connection status, enabling quick switching, and providing session management
actions.

## Interface

### Props

```dart
class SessionTabBar extends ConsumerWidget {
  const SessionTabBar({
    required this.sessions,
    required this.activeSessionId,
    this.onTabSelected,
    this.onTabClose,
    this.onTabLongPress,
    this.onAddTap,
    this.onReorder,
    super.key,
  });

  /// List of all sessions
  final List<Session> sessions;
  
  /// Currently active session ID
  final String activeSessionId;
  
  /// Called when a tab is tapped
  final void Function(String sessionId)? onTabSelected;
  
  /// Called when a tab close is requested
  final void Function(String sessionId)? onTabClose;
  
  /// Called when a tab is long-pressed (context menu)
  final void Function(String sessionId)? onTabLongPress;
  
  /// Called when add button is tapped
  final VoidCallback? onAddTap;
  
  /// Called when tabs are reordered via drag
  final void Function(int oldIndex, int newIndex)? onReorder;
}
```

### Tab Model

```dart
@freezed
class SessionTab with _$SessionTab {
  const factory SessionTab({
    required String sessionId,
    required String name,
    required SessionStatus status,
    @Default(0) int unreadCount,
    bool? hasRunningCommand,
  }) = _SessionTab;
}
```

## Visual Structure

```
┌─────────────────────────────────────────────────────────────┐
│ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───┐            │
│ │ ● prod-web│ │ ○ staging │ │ ○ homelab │ │ + │            │
│ └───────────┘ └───────────┘ └───────────┘ └───┘            │
└─────────────────────────────────────────────────────────────┘

Legend:
● = Active tab (filled dot + bold text + elevated)
○ = Background tab (outline dot + normal text)
```

### Tab States

| Status                 | Indicator         | Meaning                      |
| ---------------------- | ----------------- | ---------------------------- |
| Connected + Active     | Green filled dot  | Currently viewing, connected |
| Connected + Background | Green outline dot | Connected but not viewing    |
| Disconnected           | Red dot           | Connection lost              |
| Connecting             | Pulsing blue dot  | Connection in progress       |
| Running command        | Spinner overlay   | Command executing            |

### Unread Badge

```
┌───────────┐
│ ○ staging │
│      (3)  │  ← Unread output count
└───────────┘
```

## Behavior

### Tab Selection

- Tap to switch to session
- Active tab has elevated style
- Smooth scroll to keep active tab visible

### Tab Management

| Gesture    | Action                                   |
| ---------- | ---------------------------------------- |
| Tap        | Switch to session                        |
| Long press | Show context menu                        |
| Swipe up   | Close tab (with confirmation if running) |
| Drag       | Reorder tabs                             |
| Tap +      | Open connection picker                   |

### Context Menu Options

- Rename session
- Duplicate session
- Close session
- Close all other sessions
- Move to position

### Tab Overflow

- Horizontal scrolling when tabs exceed width
- Active tab auto-scrolls into view
- Scroll indicators at edges when scrollable

### Close Confirmation

When closing a tab with:

- Running command → "Command is running. Close anyway?"
- Unsaved changes → "Session has unsaved work. Close anyway?"

## Animations

| Animation     | Duration | Curve        |
| ------------- | -------- | ------------ |
| Tab selection | 150ms    | easeOut      |
| Tab close     | 200ms    | easeInOut    |
| Tab reorder   | 300ms    | easeOutCubic |
| Status change | 200ms    | linear       |
| Badge appear  | 100ms    | bounceOut    |

## Accessibility

- Tabs are in a horizontal scroll view with semantic grouping
- Each tab announces: name, status, unread count
- Tab bar announces total count
- Add button clearly labeled
- Swipe actions have alternatives via long-press menu

## Related Specs

- L3: [Session Management](../L3-experience/session-management.md)
- L2: [Session Service](service-session.md)
- L2: [Connection Picker](component-connection-picker.md)
- L1: [To be defined - Tab animations]
- L1: [To be defined - Unread tracking]
