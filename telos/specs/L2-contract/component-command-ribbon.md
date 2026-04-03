<!-- telos-metadata
id: L2:contract:component-command-ribbon
level: 2
title: Command Ribbon Component
parent: L3:experience:ai-command-assistance
children:
  - L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
  - L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
  - L1:function:lib/features/terminal/domain/services:applyCommandSuggestion
  - L1:function:lib/features/ai/domain/usecases:completeCommandLine
-->

# L2: Command Ribbon Component

## Overview

The Command Ribbon is the low-latency assistance surface shown above the mobile
keyboard when the user is editing a shell prompt. It provides deterministic,
token-aware suggestions plus an explicit AI escalation affordance.

The ribbon is **not** responsible for natural-language command generation on
every keystroke. Instead, it offers:
- prompt-aware completion
- token replacement
- history/snippet/symbol access
- explicit handoff to AI when deterministic completion is insufficient

## Interface

### Props

```dart
class CommandRibbon extends ConsumerWidget {
  const CommandRibbon({
    required this.sessionId,
    required this.inputState,
    required this.suggestions,
    this.onSuggestionSelected,
    this.onSymbolSelected,
    this.onAiRequested,
    this.onSnippetRequested,
    super.key,
  });

  /// Current terminal session.
  final String sessionId;

  /// Canonical prompt input state for the active shell line.
  final PromptInputState inputState;

  /// Ranked suggestions for the current input state.
  final List<CommandSuggestionChip> suggestions;

  /// Called when the user taps a deterministic suggestion chip.
  final void Function(CommandSuggestionChip suggestion)? onSuggestionSelected;

  /// Called when the user taps a shell symbol chip.
  final void Function(String symbol)? onSymbolSelected;

  /// Called when the user explicitly asks for AI help.
  final VoidCallback? onAiRequested;

  /// Called when the user wants snippets/templates.
  final VoidCallback? onSnippetRequested;
}
```

## State Models

```dart
@freezed
class PromptInputState with _$PromptInputState {
  const factory PromptInputState({
    required String text,
    required int cursorOffset,
    required bool isAtPrompt,
    required bool isEditing,
    required bool isInTuiMode,
    @Default(false) bool canShowRibbon,
  }) = _PromptInputState;
}

@freezed
class CommandSuggestionChip with _$CommandSuggestionChip {
  const factory CommandSuggestionChip({
    required String id,
    required CommandSuggestionKind kind,
    required String label,
    required String insertText,
    required TextRange replacementRange,
    String? description,
    String? trailingText,
    @Default(false) bool isAi,
    @Default(false) bool appendSpace,
    @Default(0) int priority,
  }) = _CommandSuggestionChip;
}

enum CommandSuggestionKind {
  history,
  command,
  subcommand,
  argument,
  file,
  snippet,
  symbol,
  ai,
}
```

## Visual Structure

### Idle Prompt

```
┌─────────────────────────────────────────────────────────────┐
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│ │ ls │ │ cd │ │git │ │ssh │ │..  │ │⚡  │ │🤖  │ │#   │    │
│ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘    │
│ [Recent commands, snippets, AI entry, symbols]              │
└─────────────────────────────────────────────────────────────┘
```

### Typing a Command Token

```
Input: kube|

┌─────────────────────────────────────────────────────────────┐
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌───────┐ ┌───────┐      │
│ │kubectl │ │kubectx │ │kubeadm │ │history│ │🤖 Ask │      │
│ └────────┘ └────────┘ └────────┘ └───────┘ └───────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Typing After a Known Command

```
Input: kubectl get |

┌─────────────────────────────────────────────────────────────┐
│ ┌─────┐ ┌────────┐ ┌────────────┐ ┌───────┐ ┌──────────┐   │
│ │pods │ │services│ │deployments │ │nodes  │ │🤖 Refine │   │
│ └─────┘ └────────┘ └────────────┘ └───────┘ └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Symbols Mode

```
┌─────────────────────────────────────────────────────────────┐
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌────┐ ┌────┐   │
│ │ | │ │ > │ │ < │ │ & │ │ ; │ │ $ │ │ ~ │ │ && │ │ || │   │
│ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └────┘ └────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Behavior

### Display Conditions

The ribbon is shown only when all are true:
1. the session is connected
2. Bento believes the shell is at a prompt
3. the user is editing a normal shell line
4. no full-screen TUI owns the terminal
5. command execution is not currently active

### Suggestion Priority

1. exact-context snippets
2. history matches weighted by recency/frequency
3. command-name completions
4. known subcommands/arguments
5. file/path completions
6. symbol suggestions
7. explicit AI chip

### Selection Semantics

Tapping a suggestion must:
- replace only the `replacementRange`
- preserve text before and after that range
- update cursor position predictably
- append a space only when the suggestion expects continuation
- never duplicate already-typed prefixes

### AI Escalation

The ribbon may expose a chip such as `🤖 Ask AI` or `🤖 Refine`, but:
- it must be user-initiated
- it must not run on every keystroke
- it may open Ghostwriter or invoke a line-completion flow
- it must respect privacy mode before external transmission

### TUI and Unsafe States

The ribbon must hide or disable itself when:
- vim/htop/etc. are active
- shell state is uncertain
- cursor position cannot be trusted
- output is streaming and Bento is not at a prompt

## Performance

- deterministic suggestions available within 100ms
- no model/network call in the per-keystroke suggestion path
- maximum 12 visible suggestions at once
- ranking logic runs in memory and is debounce-safe
- AI escalation is separately debounced/throttled from the ribbon

## Related Specs

- L3: [AI Command Assistance](../L3-experience/ai-command-assistance.md)
- L2: [Ghostwriter Modal Component](component-ghostwriter-modal.md)
- L2: [AI Gateway Service](service-ai-gateway.md)
- L1: [prompt_input_controller](../L1-function/terminal-prompt-input-controller.md)
- L1: [rankCommandSuggestions](../L1-function/terminal-rank-command-suggestions.md)
- L1: [applyCommandSuggestion](../L1-function/terminal-apply-command-suggestion.md)
- L1: [completeCommandLine](../L1-function/ai-complete-command-line.md)
