<!-- telos-metadata
id: L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
level: 1
title: rankCommandSuggestions
parent: L2:contract:component-command-ribbon
-->

# L1: rankCommandSuggestions

## Purpose

Produces a ranked list of deterministic command-ribbon suggestions from prompt
input state, history, command knowledge, snippets, and symbols.

## Signature

```dart
List<CommandSuggestionChip> rankCommandSuggestions({
  required PromptInputState inputState,
  required List<HistoryEntry> history,
  required CommandKnowledge knowledge,
  List<String> snippets = const [],
  List<String> symbols = const [],
  int maxSuggestions = 12,
});
```

## TDD Scenarios

### Scenario: Show idle suggestions when prompt is empty

```gherkin
Given inputState.text is empty
And inputState.canShowRibbon is true
When rankCommandSuggestions is called
Then recent history and common commands are returned
And the result count is less than or equal to maxSuggestions
```

### Scenario: Rank history above generic commands for same prefix

```gherkin
Given inputState.text equals "kub"
And history contains "kubectl get pods -n production"
When rankCommandSuggestions is called
Then a history-based kubectl suggestion appears before generic command knowledge
```

### Scenario: Suggest known subcommands after a command and space

```gherkin
Given inputState.text equals "docker "
And the cursor is at the end of the line
When rankCommandSuggestions is called
Then suggestions include "run", "ps", and "compose"
And their kind equals subcommand
```

### Scenario: Suggest nested arguments after known command context

```gherkin
Given inputState.text equals "kubectl get "
When rankCommandSuggestions is called
Then suggestions include "pods", "services", and "deployments"
And each suggestion targets the active token range
```

### Scenario: Deduplicate identical labels from multiple sources

```gherkin
Given history and command knowledge both produce "git"
When rankCommandSuggestions is called
Then only one visible "git" suggestion is returned
And the higher-priority source wins
```

### Scenario: Do not suggest when ribbon cannot be shown

```gherkin
Given inputState.canShowRibbon is false
When rankCommandSuggestions is called
Then the result is empty
```

## Implementation Notes

- Per-keystroke path must remain deterministic and local
- Ranking should prefer user history over static knowledge
- Suggestions should carry a replacement range, not just display text
- AI chips may be appended separately but must not displace all deterministic
  suggestions

## Related Specs

- L2: [Command Ribbon Component](../L2-contract/component-command-ribbon.md)
