<!-- telos-metadata
id: L2:contract:component-ghostwriter-modal
level: 2
title: Ghostwriter Modal Component
parent: L3:experience:ai-command-assistance
children: []
-->

# L2: Ghostwriter Modal Component

## Overview

The Ghostwriter Modal is the AI-powered natural language to command interface.
Users describe what they want to do, and the AI generates the appropriate CLI
command with explanation.

## Interface

### Props

```dart
class GhostwriterModal extends ConsumerWidget {
  const GhostwriterModal({
    required this.sessionId,
    required this.shellContext,
    this.onCommandAccepted,
    this.onDismiss,
    this.initialQuery,
    super.key,
  });

  /// Current session for context
  final String sessionId;
  
  /// Shell context (OS, shell type, cwd, etc.)
  final ShellContext shellContext;
  
  /// Called when user accepts a command
  final void Function(String command, {bool execute})? onCommandAccepted;
  
  /// Called when modal is dismissed
  final VoidCallback? onDismiss;
  
  /// Pre-fill query (e.g., from voice input)
  final String? initialQuery;
}
```

### State

```dart
@freezed
class GhostwriterState with _$GhostwriterState {
  const factory GhostwriterState.idle() = _Idle;
  
  const factory GhostwriterState.loading({
    required String query,
  }) = _Loading;
  
  const factory GhostwriterState.success({
    required String query,
    required CommandSuggestion suggestion,
  }) = _Success;
  
  const factory GhostwriterState.error({
    required String query,
    required AIFailure failure,
  }) = _Error;
  
  const factory GhostwriterState.editing({
    required String query,
    required CommandSuggestion originalSuggestion,
    required String editedCommand,
  }) = _Editing;
}
```

## Visual Structure

### Idle State

```
┌─────────────────────────────────────────────────────────────┐
│ 🤖 AI GHOSTWRITER                                    [✕]    │
├─────────────────────────────────────────────────────────────┤
│ What do you want to do?                                      │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                                                         │ │
│ │ Type your request in plain English...                   │ │
│ │                                                         │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ EXAMPLES:                                                    │
│ • "find all log files larger than 100MB"                    │
│ • "show disk usage sorted by size"                          │
│ • "list docker containers that exited with error"           │
│                                                              │
│ [🎤 Voice]                                        [Generate] │
└─────────────────────────────────────────────────────────────┘
```

### Loading State

```
┌─────────────────────────────────────────────────────────────┐
│ 🤖 AI GHOSTWRITER                                    [✕]    │
├─────────────────────────────────────────────────────────────┤
│ What do you want to do?                                      │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ find all log files larger than 100MB modified today     │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                                                         │ │
│ │              ◐ Generating command...                    │ │
│ │                                                         │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ Using: Local AI (Qwen 0.5B)                                 │
└─────────────────────────────────────────────────────────────┘
```

### Success State

```
┌─────────────────────────────────────────────────────────────┐
│ 🤖 AI GHOSTWRITER                                    [✕]    │
├─────────────────────────────────────────────────────────────┤
│ What do you want to do?                                      │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ find all log files larger than 100MB modified today     │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ SUGGESTED COMMAND:                                           │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ find /var/log -name "*.log" -size +100M -mtime 0        │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ 💡 Finds .log files in /var/log that are larger than 100MB │
│    and were modified in the last 24 hours.                  │
│                                                              │
│ Confidence: ████████░░ 85%                                  │
│                                                              │
│ [Regenerate]          [Edit] [Copy] [Execute]               │
└─────────────────────────────────────────────────────────────┘
```

### Error State

```
┌─────────────────────────────────────────────────────────────┐
│ 🤖 AI GHOSTWRITER                                    [✕]    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ ⚠️ Unable to generate command                               │
│                                                              │
│ The AI couldn't understand your request. Try:               │
│ • Being more specific about what you want                   │
│ • Including the target directory or file                    │
│ • Breaking complex requests into simpler parts              │
│                                                              │
│ [Try Again]                         [Search History Instead] │
└─────────────────────────────────────────────────────────────┘
```

## Behavior

### Query Submission

1. User types natural language query
2. Tap "Generate" or press Enter
3. Show loading state
4. Send to AI Gateway
5. Display result or error

### Voice Input

1. Tap microphone button
2. Show listening indicator
3. Convert speech to text
4. Auto-submit when speech ends

### Command Actions

| Action     | Behavior                                            |
| ---------- | --------------------------------------------------- |
| Execute    | Insert command into terminal, run it, dismiss modal |
| Copy       | Copy command to clipboard, show confirmation        |
| Edit       | Switch to editing mode with inline text field       |
| Regenerate | Request new suggestion with same query              |

### Editing Mode

- Command becomes editable text field
- "Execute" sends edited version
- "Reset" returns to original suggestion
- Edit history tracked for learning

### Dangerous Command Warning

If command contains potentially dangerous operations:

```
⚠️ This command may be destructive:
   rm -rf /var/log/*
   
Are you sure you want to execute it?
[Cancel] [Execute Anyway]
```

Triggers: `rm -rf`, `dd if=`, `mkfs`, `DROP`, `DELETE FROM`, `chmod 777`, etc.

## Accessibility

- Modal announced with title
- Query field has clear label
- Loading state announced
- Command suggestion selectable
- All buttons labeled
- Voice input has visual feedback

## Related Specs

- L3: [AI Command Assistance](../L3-experience/ai-command-assistance.md)
- L3: [Mobile Vibe Coding](../L3-experience/mobile-vibe-coding.md)
- L2: [AI Gateway Service](service-ai-gateway.md)
- L1: [To be defined - Voice input handler]
- L1: [To be defined - Dangerous command detector]
