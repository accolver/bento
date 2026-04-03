<!-- telos-metadata
id: L1:function:lib/features/terminal/domain/services:applyCommandSuggestion
level: 1
title: applyCommandSuggestion
parent: L2:contract:component-command-ribbon
-->

# L1: applyCommandSuggestion

## Purpose

Applies a selected ribbon suggestion to the current prompt input line without
corrupting surrounding text.

## Signature

```dart
PromptInputState applyCommandSuggestion({
  required PromptInputState current,
  required CommandSuggestionChip suggestion,
});
```

## TDD Scenarios

### Scenario: Replace partial command token

```gherkin
Given current.text equals "kub"
And current.cursorOffset equals 3
And suggestion.insertText equals "kubectl"
And suggestion.replacementRange covers the token "kub"
When applyCommandSuggestion is called
Then the result text equals "kubectl "
And the cursor moves to the end of the inserted command
```

### Scenario: Replace subcommand only

```gherkin
Given current.text equals "docker co"
And suggestion.insertText equals "compose"
And suggestion.replacementRange covers only "co"
When applyCommandSuggestion is called
Then the result text equals "docker compose "
And "docker" remains unchanged
```

### Scenario: Insert symbol at cursor without deleting surrounding text

```gherkin
Given current.text equals "cat file.txt"
And current.cursorOffset equals 12
And suggestion.kind equals symbol
And suggestion.insertText equals " | "
When applyCommandSuggestion is called
Then the result text equals "cat file.txt | "
```

### Scenario: Preserve trailing text after cursor

```gherkin
Given current.text equals "git st main"
And current.cursorOffset is within "st"
And suggestion.insertText equals "status"
When applyCommandSuggestion is called
Then the result text equals "git status main"
And the trailing token "main" remains
```

### Scenario: Ignore invalid replacement ranges safely

```gherkin
Given a suggestion has a replacementRange outside the current text bounds
When applyCommandSuggestion is called
Then the function clamps the range to safe bounds
And no exception is thrown
```

## Implementation Notes

- This function should operate on structured ranges, never raw append-only text
- Space-appending behavior should be explicit and testable
- The result must remain valid even when range data is stale or partially wrong

## Related Specs

- L2: [Command Ribbon Component](../L2-contract/component-command-ribbon.md)
