<!-- telos-metadata
id: L2:contract:component-command-ribbon
level: 2
title: Command Ribbon Component
parent: L3:experience:ai-command-assistance
children: []
-->

# L2: Command Ribbon Component

## Overview

The Command Ribbon is a horizontal, scrollable strip positioned above the
keyboard that provides intelligent command completion, common symbols, and quick
actions based on the current input context.

## Interface

### Props

```dart
class CommandRibbon extends ConsumerWidget {
  const CommandRibbon({
    required this.sessionId,
    required this.currentInput,
    required this.cursorPosition,
    this.onSuggestionSelected,
    this.onSymbolSelected,
    this.onAITap,
    this.onSnippetTap,
    super.key,
  });

  /// Current session ID for context
  final String sessionId;
  
  /// Current text in the input field
  final String currentInput;
  
  /// Cursor position in input
  final int cursorPosition;
  
  /// Called when a suggestion chip is tapped
  final void Function(Suggestion suggestion)? onSuggestionSelected;
  
  /// Called when a symbol is selected from symbol tray
  final void Function(String symbol)? onSymbolSelected;
  
  /// Called when AI button is tapped
  final VoidCallback? onAITap;
  
  /// Called when snippet button is tapped
  final VoidCallback? onSnippetTap;
}
```

### Suggestion Model

```dart
@freezed
class Suggestion with _$Suggestion {
  /// From command history
  const factory Suggestion.history({
    required String command,
    required int useCount,
    DateTime? lastUsed,
  }) = _HistorySuggestion;
  
  /// From PATH commands
  const factory Suggestion.path({
    required String command,
  }) = _PathSuggestion;
  
  /// Subcommand completion (e.g., "git" → "status", "add")
  const factory Suggestion.subcommand({
    required String subcommand,
    String? description,
  }) = _SubcommandSuggestion;
  
  /// Argument completion (e.g., "kubectl get" → "pods", "services")
  const factory Suggestion.argument({
    required String argument,
    String? description,
  }) = _ArgumentSuggestion;
  
  /// File/path completion
  const factory Suggestion.file({
    required String path,
    required bool isDirectory,
  }) = _FileSuggestion;
  
  /// Snippet suggestion
  const factory Suggestion.snippet({
    required String id,
    required String name,
    required String preview,
  }) = _SnippetSuggestion;
}
```

## Visual Structure

### Idle Mode (no input)

```
┌─────────────────────────────────────────────────────────────┐
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│ │ ls │ │ cd │ │ cat│ │grep│ │sudo│ │ .. │ │ 🤖 │ │ 📋 │    │
│ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘    │
│ [Recent commands + AI + Snippets]                           │
└─────────────────────────────────────────────────────────────┘
```

### Typing Mode (partial command)

```
┌─────────────────────────────────────────────────────────────┐
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐     │
│ │kubectl │ │kubectx │ │kubens  │ │kubeadm │ │kubelet │     │
│ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘     │
│ [Completions matching "kube"]                               │
└─────────────────────────────────────────────────────────────┘
```

### Subcommand Mode (after command + space)

```
┌─────────────────────────────────────────────────────────────┐
│ ┌────┐ ┌─────┐ ┌──────┐ ┌────────┐ ┌─────┐ ┌──────┐       │
│ │get │ │apply│ │delete│ │describe│ │logs │ │exec  │       │
│ └────┘ └─────┘ └──────┘ └────────┘ └─────┘ └──────┘       │
│ [Subcommands for "kubectl"]                                 │
└─────────────────────────────────────────────────────────────┘
```

### Symbol Mode (long-press to activate)

```
┌─────────────────────────────────────────────────────────────┐
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐    │
│ │ | │ │ > │ │ < │ │ & │ │ ; │ │ $ │ │ ~ │ │ / │ │ \ │    │
│ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘    │
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐    │
│ │ " │ │ ' │ │ ` │ │ ( │ │ ) │ │ [ │ │ ] │ │ { │ │ } │    │
│ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘    │
└─────────────────────────────────────────────────────────────┘
```

## Behavior

### Suggestion Priority

1. Snippets matching current input
2. History commands (weighted by recency + frequency)
3. PATH commands matching prefix
4. Subcommand completions (context-aware)
5. File/path completions

### Context-Aware Completions

Known command structures:

```dart
const commandKnowledge = {
  'git': ['status', 'add', 'commit', 'push', 'pull', 'checkout', ...],
  'docker': ['run', 'ps', 'images', 'build', 'compose', ...],
  'kubectl': ['get', 'apply', 'delete', 'describe', 'logs', ...],
  'npm': ['install', 'run', 'start', 'test', 'build', ...],
  // ... more commands
};
```

### Interactions

| Gesture           | Action                      |
| ----------------- | --------------------------- |
| Tap chip          | Insert suggestion at cursor |
| Long press ribbon | Show symbol tray            |
| Tap 🤖            | Open AI Ghostwriter         |
| Tap 📋            | Open snippet picker         |
| Swipe horizontal  | Scroll through suggestions  |

### Chip Appearance

| Type       | Icon  | Color   |
| ---------- | ----- | ------- |
| History    | 🕐    | Default |
| PATH       | ▸     | Default |
| Subcommand | →     | Accent  |
| File       | 📄/📁 | Default |
| Snippet    | ⚡    | Accent  |

## Performance

- Suggestions computed debounced (100ms delay)
- Maximum 20 suggestions loaded at once
- Lazy loading for file completions
- Command knowledge cached in memory

## Related Specs

- L3: [AI Command Assistance](../L3-experience/ai-command-assistance.md)
- L3: [Mobile Vibe Coding](../L3-experience/mobile-vibe-coding.md)
- L2: [Snippet Service](service-snippet.md)
- L1: [To be defined - Suggestion ranker]
- L1: [To be defined - Command knowledge base]
