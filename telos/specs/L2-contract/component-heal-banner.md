<!-- telos-metadata
id: L2:contract:component-heal-banner
level: 2
title: Heal Banner Component
parent: L3:experience:error-recovery
children: []
-->

# L2: Heal Banner Component

## Overview

The Heal Banner appears on failed command blocks when the AI has a suggested
fix. It provides a non-intrusive way to offer one-tap error resolution.

## Interface

### Props

```dart
class HealBanner extends StatelessWidget {
  const HealBanner({
    required this.fix,
    required this.isExpanded,
    this.onExpand,
    this.onApply,
    this.onDismiss,
    this.onViewAlternatives,
    super.key,
  });

  /// The suggested fix from AI
  final CommandFix fix;
  
  /// Whether the banner is expanded to show details
  final bool isExpanded;
  
  /// Called when banner is tapped to expand
  final VoidCallback? onExpand;
  
  /// Called when "Apply Fix" is tapped
  final VoidCallback? onApply;
  
  /// Called when dismiss/X is tapped
  final VoidCallback? onDismiss;
  
  /// Called when "See alternatives" is tapped
  final VoidCallback? onViewAlternatives;
}
```

## Visual Structure

### Collapsed State (in block)

```
┌──────────────────────────────────────────────────────────────┐
│ 🔧 Fix available: Add sudo for permission         [Apply ▶] │
└──────────────────────────────────────────────────────────────┘
```

### Expanded State

```
┌──────────────────────────────────────────────────────────────┐
│ 🔧 FIX AVAILABLE                                       [✕]  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ PROBLEM:                                                     │
│ Permission denied when trying to write to /usr/local/lib.   │
│ This directory requires root access.                        │
│                                                              │
│ SUGGESTED FIX:                                               │
│ ┌──────────────────────────────────────────────────────────┐│
│ │ sudo npm install                                         ││
│ └──────────────────────────────────────────────────────────┘│
│                                                              │
│ This will run the command with elevated privileges.         │
│                                                              │
│ [See alternatives]                         [Apply Fix]      │
└──────────────────────────────────────────────────────────────┘
```

### Fix Types with Icons

| Fix Type            | Icon | Label                      |
| ------------------- | ---- | -------------------------- |
| `addSudo`           | 🔐   | "Run with sudo"            |
| `installPackage`    | 📦   | "Install missing package"  |
| `fixSyntax`         | ✏️   | "Fix syntax error"         |
| `changePermissions` | 🔓   | "Change permissions"       |
| `createDirectory`   | 📁   | "Create missing directory" |
| `fixPath`           | 📍   | "Correct file path"        |
| `fixArguments`      | ⚙️   | "Fix command arguments"    |
| `other`             | 🔧   | "Suggested fix"            |

## Behavior

### Banner Lifecycle

1. Command fails with non-zero exit code
2. AI analyzes command + stderr (async, < 500ms target)
3. If fix found, banner appears with slide-in animation
4. User can expand, apply, or dismiss

### Apply Fix Flow

1. User taps "Apply Fix"
2. If `requiresConfirmation`, show confirmation dialog
3. Execute fixed command
4. Create new block for fixed command
5. Banner auto-dismisses
6. Log healing success/failure for learning

### Confirmation Required For

- Commands with `sudo`
- Commands that delete files
- Commands that change permissions broadly
- Commands that affect system configuration

### Alternatives Modal

When "See alternatives" is tapped:

```
┌──────────────────────────────────────────────────────────────┐
│ ALTERNATIVE FIXES                                      [✕]  │
├──────────────────────────────────────────────────────────────┤
│ 1. Run with sudo (recommended)                              │
│    └─ sudo npm install                                      │
│                                                    [Apply]  │
├──────────────────────────────────────────────────────────────┤
│ 2. Install to user directory                                │
│    └─ npm install --prefix ~/.local                         │
│                                                    [Apply]  │
├──────────────────────────────────────────────────────────────┤
│ 3. Fix npm permissions                                      │
│    └─ sudo chown -R $(whoami) /usr/local/lib/node_modules   │
│                                                    [Apply]  │
└──────────────────────────────────────────────────────────────┘
```

### Dismiss Behavior

- Tapping X dismisses banner
- Banner can reappear via "Heal" button in block menu
- Dismissal not persisted (reappears on app restart if still relevant)

## Animations

| Animation          | Duration | Curve        |
| ------------------ | -------- | ------------ |
| Banner appear      | 200ms    | easeOutCubic |
| Banner expand      | 150ms    | easeInOut    |
| Banner dismiss     | 150ms    | easeIn       |
| Apply confirmation | 100ms    | easeOut      |

## Accessibility

- Banner announced when it appears
- Fix type and action clearly labeled
- Expand/collapse state announced
- Apply and dismiss buttons accessible
- Confirmation dialogs properly modal

## Related Specs

- L3: [Error Recovery](../L3-experience/error-recovery.md)
- L2: [AI Gateway Service](service-ai-gateway.md)
- L2: [Block Widget](component-block-widget.md)
- L1: [To be defined - healError function]
- L1: [To be defined - Fix confirmation logic]
