<!-- telos-metadata
id: L2:contract:component-connection-picker
level: 2
title: Connection Picker Component
parent: L3:experience:session-management
children: []
-->

# L2: Connection Picker Component

## Overview

The Connection Picker is a modal/sheet that allows users to select a host to
connect to, showing recent connections, saved hosts organized in folders, and
Tailscale nodes.

## Interface

### Props

```dart
class ConnectionPicker extends ConsumerWidget {
  const ConnectionPicker({
    this.onHostSelected,
    this.onTailscaleNodeSelected,
    this.onAddNewHost,
    this.onDismiss,
    super.key,
  });

  /// Called when a saved host is selected
  final void Function(Host host)? onHostSelected;
  
  /// Called when a Tailscale node is selected
  final void Function(TailscaleNode node)? onTailscaleNodeSelected;
  
  /// Called when "Add New Host" is tapped
  final VoidCallback? onAddNewHost;
  
  /// Called when picker is dismissed without selection
  final VoidCallback? onDismiss;
}
```

## Visual Structure

```
┌─────────────────────────────────────────────────────────────┐
│ NEW CONNECTION                                        [✕]   │
├─────────────────────────────────────────────────────────────┤
│ 🔍 Search hosts...                                          │
├─────────────────────────────────────────────────────────────┤
│ RECENT                                                       │
│ ├─ 🖥 prod-web-01      user@192.168.1.10        2h ago     │
│ ├─ 🖥 staging-api      deploy@staging.local     yesterday  │
│ └─ 🖥 homelab-nas      admin@10.0.0.50          3d ago     │
├─────────────────────────────────────────────────────────────┤
│ TAILSCALE (4 online)                                  [↻]   │
│ ├─ 🟢 macbook-pro      100.64.0.1                          │
│ ├─ 🟢 home-server      100.64.0.2                          │
│ ├─ 🟢 raspberry-pi     100.64.0.3                          │
│ └─ 🔴 work-laptop      100.64.0.4 (offline)                │
├─────────────────────────────────────────────────────────────┤
│ SAVED HOSTS                                                  │
│ ├─ 📁 Production (3)                                    [▶] │
│ ├─ 📁 Staging (2)                                       [▶] │
│ └─ 📁 Personal (5)                                      [▶] │
│                                                              │
│ ├─ 🖥 unfiled-server   root@example.com                    │
├─────────────────────────────────────────────────────────────┤
│ [+ Add New Host]                                            │
└─────────────────────────────────────────────────────────────┘
```

### Expanded Folder

```
│ ├─ 📂 Production (3)                                    [▼] │
│ │   ├─ 🖥 web-01       deploy@10.0.1.10                    │
│ │   ├─ 🖥 web-02       deploy@10.0.1.11                    │
│ │   └─ 🖥 api-01       deploy@10.0.1.20                    │
```

## Sections

### Recent

- Last 5 connected hosts
- Sorted by last connection time
- Shows relative time ("2h ago", "yesterday")
- Tapping connects immediately

### Tailscale

- Only shown if Tailscale app is installed
- Shows all nodes in tailnet
- Online/offline status indicated
- Refresh button to re-query
- Tapping online node prompts for username, then connects

### Saved Hosts

- Organized into collapsible folders
- Unfiled hosts shown at bottom
- Folders sorted by user preference
- Hosts show name and connection string

## Behavior

### Search

- Filters across all sections
- Matches name, hostname, username, tags
- Results grouped by section
- Empty state: "No hosts found"

### Host Selection

1. User taps host
2. If Mosh enabled, attempt Mosh connection
3. Else, SSH connection
4. Picker dismisses, session tab created

### Tailscale Selection

1. User taps online Tailscale node
2. Prompt for username (with remembered default)
3. Create temporary host config
4. Connect via SSH (Tailscale handles routing)

### Folder Management

- Tap folder to expand/collapse
- Long-press folder for rename/delete
- Drag hosts between folders
- Create new folder via menu

### Empty States

| State                 | Message                                      |
| --------------------- | -------------------------------------------- |
| No recent             | "No recent connections"                      |
| Tailscale unavailable | "Tailscale not installed" [Learn more]       |
| No saved hosts        | "No saved hosts yet" [+ Add your first host] |
| Search no results     | "No hosts matching '[query]'"                |

## Animations

| Animation     | Duration | Curve        |
| ------------- | -------- | ------------ |
| Sheet appear  | 300ms    | easeOutCubic |
| Sheet dismiss | 250ms    | easeInCubic  |
| Folder expand | 200ms    | easeInOut    |
| List item tap | 100ms    | easeOut      |

## Accessibility

- Sheet announced as modal
- Sections are semantic groups
- Search field focused on open
- Status indicators have labels
- Folders announce expanded/collapsed state

## Related Specs

- L3: [Session Management](../L3-experience/session-management.md)
- L2: [Host Service](service-host.md)
- L2: [Session Service](service-session.md)
- L1: [To be defined - Host list filtering]
- L1: [To be defined - Tailscale integration]
