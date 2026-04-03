<!-- telos-metadata
id: L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
level: 1
title: prompt_input_controller
parent: L2:contract:component-command-ribbon
-->

# L1: prompt_input_controller

## Purpose

Tracks the user's editable shell prompt state for a single terminal session so
that the command ribbon can offer safe, token-aware suggestions.

## Signature

```dart
class PromptInputController extends StateNotifier<PromptInputState> {
  PromptInputController(String sessionId);

  void onPromptDetected();
  void onCommandStarted();
  void onTuiModeEntered();
  void onTuiModeExited();

  void insertText(String text);
  void replaceRange(TextRange range, String replacement);
  void moveCursor(int newOffset);
  void deleteBackward();
  void clear();
}
```

## TDD Scenarios

### Scenario: Enter prompt state after shell prompt detected

```gherkin
Given a session is not currently editing a prompt
When onPromptDetected is called
Then state.isAtPrompt is true
And state.canShowRibbon is true
And state.isEditing is true
```

### Scenario: Hide ribbon when command starts running

```gherkin
Given state.isAtPrompt is true
And state.text equals "kubectl get pods"
When onCommandStarted is called
Then state.isAtPrompt is false
And state.canShowRibbon is false
And state.text is cleared
```

### Scenario: Disable prompt tracking during TUI mode

```gherkin
Given a user is editing a prompt
When onTuiModeEntered is called
Then state.isInTuiMode is true
And state.canShowRibbon is false
And the controller stops offering completions
When onTuiModeExited is called
Then state.isInTuiMode is false
And normal prompt tracking may resume on next prompt detection
```

### Scenario: Insert text at cursor position

```gherkin
Given state.text equals "kubectl get "
And state.cursorOffset equals 12
When insertText is called with "pods"
Then state.text equals "kubectl get pods"
And state.cursorOffset equals 16
```

### Scenario: Replace only active token range

```gherkin
Given state.text equals "kub get pods"
And state.cursorOffset is inside the token "kub"
When replaceRange is called for the token range with "kubectl"
Then state.text equals "kubectl get pods"
And the remainder of the line is preserved
```

### Scenario: Backspace updates text safely at start of line

```gherkin
Given state.text is empty
And state.cursorOffset equals 0
When deleteBackward is called
Then state.text remains empty
And state.cursorOffset remains 0
And no exception is thrown
```

### Scenario: Cursor movement is clamped to valid range

```gherkin
Given state.text equals "git status"
When moveCursor is called with 999
Then state.cursorOffset equals state.text.length
When moveCursor is called with -5
Then state.cursorOffset equals 0
```

## Implementation Notes

- This controller models Bento's best-known prompt-editing state, not the
  remote shell's entire line editor implementation
- It must avoid making unsafe assumptions when prompt state is uncertain
- It should integrate with prompt detection and TUI mode detection rather than
  infer prompt status solely from keystrokes
- It should be session-scoped

## Related Specs

- L2: [Command Ribbon Component](../L2-contract/component-command-ribbon.md)
