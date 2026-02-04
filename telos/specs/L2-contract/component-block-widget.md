<!-- telos-metadata
id: L2:contract:component-block-widget
level: 2
title: Block Widget Component
parent: L3:experience:incident-response
children: []
-->

# L2: Block Widget Component

## Overview

The Block Widget displays a single Semantic Block - a command with its output,
status, and interactive controls. It's the core visual unit of Bento's terminal
interface.

## Interface

### Props

```dart
class BlockWidget extends ConsumerWidget {
  const BlockWidget({
    required this.block,
    this.onTap,
    this.onLongPress,
    this.onCollapse,
    this.onExpand,
    this.onPin,
    this.onCopy,
    this.onSearch,
    this.onHeal,
    this.onTappableElementTap,
    this.searchQuery,
    this.isActive = false,
    super.key,
  });

  /// The block data to display
  final Block block;
  
  /// Called when block header is tapped
  final VoidCallback? onTap;
  
  /// Called when block is long-pressed (shows context menu)
  final VoidCallback? onLongPress;
  
  /// Called when collapse is requested
  final VoidCallback? onCollapse;
  
  /// Called when expand is requested
  final VoidCallback? onExpand;
  
  /// Called when pin toggle is requested
  final VoidCallback? onPin;
  
  /// Called when copy is requested
  final VoidCallback? onCopy;
  
  /// Called when search within block is requested
  final VoidCallback? onSearch;
  
  /// Called when heal button is tapped (for failed blocks)
  final VoidCallback? onHeal;
  
  /// Called when a tappable element is tapped
  final void Function(TappableElement element)? onTappableElementTap;
  
  /// Current search query for highlighting
  final String? searchQuery;
  
  /// Whether this block is currently active/selected
  final bool isActive;
}
```

## Visual Structure

```
┌─────────────────────────────────────────────────────────────┐
│ [▼] $ kubectl get pods -n production          [📋] [⋮]     │ ← Header
│     ┌─ Status: Success (0) ─────── 2.3s ─── 14:32:05 ──┐   │ ← Status Bar
├─────┴──────────────────────────────────────────────────┴────┤
│ NAME                    READY   STATUS    RESTARTS   AGE    │
│ api-server-7d4f9-abc    1/1     Running   0          3d     │ ← Output
│ worker-5c8b2-def        1/1     Running   2          3d     │   (with tappable
│ redis-cache-xyz         1/1     Running   0          5d     │    elements)
│                                                              │
│ [AI: 3 pods running in production, all healthy]             │ ← AI Summary
├──────────────────────────────────────────────────────────────┤
│ [Collapse] [Search] [Copy All] [Share] [Pin]                │ ← Actions
└──────────────────────────────────────────────────────────────┘
```

### Collapsed State

```
┌─────────────────────────────────────────────────────────────┐
│ [▶] $ kubectl get pods -n production    ✓ 0   2.3s   [📋]  │
│     [3 pods running, all healthy]                           │
└─────────────────────────────────────────────────────────────┘
```

## Behavior

### State-Based Styling

| Status      | Left Border    | Icon    | Header BG       |
| ----------- | -------------- | ------- | --------------- |
| `running`   | Blue (pulsing) | Spinner | Default         |
| `success`   | Green          | ✓       | Default         |
| `failed`    | Red            | ✗       | Slight red tint |
| `cancelled` | Yellow         | ⊘       | Default         |

### Interactions

| Gesture              | Action                     |
| -------------------- | -------------------------- |
| Tap header           | Toggle collapse/expand     |
| Swipe left           | Collapse (if expanded)     |
| Swipe right          | Expand (if collapsed)      |
| Long press           | Show context menu          |
| Tap copy icon        | Copy command to clipboard  |
| Tap ⋮ menu           | Show more actions          |
| Tap tappable element | Show element actions       |
| Tap "Heal" (failed)  | Trigger error healing flow |

### Tappable Elements

Elements detected and made interactive:

- **IP addresses**: Copy, SSH, Ping, Add to hosts
- **File paths**: Copy, View, Edit, Download
- **URLs**: Copy, Open in browser
- **JSON objects**: Expand in tree view
- **Git commits**: Copy, Show commit details

### Animations

| Animation       | Duration | Curve         |
| --------------- | -------- | ------------- |
| Collapse/Expand | 200ms    | easeInOut     |
| Status change   | 150ms    | easeOut       |
| Highlight fade  | 300ms    | linear        |
| Pulse (running) | 1000ms   | linear (loop) |

### Search Highlighting

When `searchQuery` is provided:

- All matches highlighted with yellow background
- Current match has distinct highlight
- Match count shown in header
- Navigation arrows to jump between matches

## Accessibility

- Full VoiceOver/TalkBack support
- Semantic labels for all interactive elements
- Collapse/expand state announced
- Status announced on change
- Minimum tap target: 44x44 points

## Related Specs

- L3: [Incident Response](../L3-experience/incident-response.md)
- L3: [Error Recovery](../L3-experience/error-recovery.md)
- L2: [Block Service](service-block.md)
- L1: [To be defined - Block status animations]
- L1: [To be defined - Tappable element renderer]
