<!-- telos-metadata
id: L3:experience:session-management
level: 3
title: Session Management
parent: L4:purpose
children:
  - L2:contract:service-session
  - L2:contract:service-host
  - L2:contract:component-tab-bar
  - L2:contract:component-connection-picker
  - L2:contract:component-modifier-drawer
-->

# L3: Session Management

## Overview

A user manages multiple concurrent terminal sessions across different servers,
switching between them fluidly while maintaining full context and history in
each.

## User Story

As a **developer working with multiple environments**, I want to **manage
several terminal sessions in tabs** so that **I can quickly switch between dev,
staging, and production without losing context**.

## Journey Steps

1. **Create First Session**
   - User action: Opens Bento, taps "+" or selects a saved host
   - System response: Opens connection picker with recent, Tailscale, and saved
     hosts
   - Success criteria: Connection picker shows organized host list

2. **Connect to Host**
   - User action: Selects "prod-web-01" from saved hosts
   - System response: Creates new tab, initiates Mosh/SSH connection, shows
     progress
   - Success criteria: Tab appears with connection status, terminal ready within
     3s

3. **Open Additional Sessions**
   - User action: Taps "+" button while in active session
   - System response: Opens connection picker, previous session remains in
     background
   - Success criteria: Can open multiple tabs without disconnecting existing

4. **Switch Between Sessions**
   - User action: Taps on tab or swipes left/right on terminal area
   - System response: Animates to selected session, restores scroll position and
     state
   - Success criteria: Smooth transition (< 300ms), full context preserved

5. **Monitor Session Status**
   - User action: Glances at tab bar
   - System response: Shows connection status via colored indicators
   - Success criteria: Can see which sessions are connected/disconnected at a
     glance

6. **Close Session**
   - User action: Long-press on tab, selects "Close" (or swipes up on tab)
   - System response: Confirms if commands running, disconnects, removes tab
   - Success criteria: Session closed, blocks persisted for history

7. **Resume After App Restart**
   - User action: Reopens Bento after closing app
   - System response: Restores all session tabs, reconnects Mosh sessions
     automatically
   - Success criteria: All tabs restored, Mosh sessions reconnected, block
     history intact

## Tab Bar Behavior

| Indicator    | Meaning                       |
| ------------ | ----------------------------- |
| Green dot    | Connected, active session     |
| Yellow dot   | Connected, background session |
| Red dot      | Disconnected                  |
| Pulsing dot  | Connecting/Reconnecting       |
| Number badge | Unread output since last view |

## Edge Cases

- **Max sessions reached**: Warn user, suggest closing unused sessions (soft
  limit: 10)
- **Session disconnects**: Show red indicator, offer reconnect button
- **App backgrounded**: Keep Mosh sessions alive, SSH may timeout
- **Low memory**: Warn before opening new session, suggest closing old ones
- **Connection picker empty**: Show "Add New Host" prominently, offer Tailscale
  setup

## Session Persistence

- **Block history**: All blocks persisted to SQLite, survives app restart
- **Tab order**: Preserved across restarts
- **Scroll position**: Restored when switching tabs
- **Active session**: Remembered and focused on restart
- **Mosh state**: Serialized for session resume

## Analytics Events

- `session_created`: New session tab opened
- `session_connected`: Successfully connected to host
- `session_switched`: User switched between tabs
- `session_closed`: User closed a session
- `session_restored`: Session restored after app restart
- `session_reconnected`: Mosh session reconnected automatically

## Success Metrics

- Average sessions per user: Track typical usage patterns
- Session switch time: < 300ms
- Session restore success: > 99% for Mosh sessions
- Tab persistence: 100% of tabs survive app restart

## Related Specs

- L2: [To be defined - Session state contract]
- L2: [To be defined - Tab bar component contract]
- L2: [To be defined - Connection picker contract]
- L1: [To be defined - Session persistence functions]
- L1: [To be defined - Mosh state serialization]
