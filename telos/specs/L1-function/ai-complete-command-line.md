<!-- telos-metadata
id: L1:function:lib/features/ai/domain/usecases:completeCommandLine
level: 1
title: completeCommandLine
parent: L2:contract:component-command-ribbon
-->

# L1: completeCommandLine

## Purpose

Uses AI to refine or complete the current shell line when the user explicitly
requests help from the command ribbon.

## Signature

```dart
Future<Either<AIFailure, CommandSuggestion>> completeCommandLine({
  required String partialLine,
  required ShellContext context,
  String? userIntent,
});
```

## TDD Scenarios

### Scenario: Explicit AI completion of a partial line

```gherkin
Given the user has typed "aws s3api list-objects --bucket my-bucket"
And the user explicitly taps the AI chip
When completeCommandLine is called
Then AI receives the partial line and shell context
And Right(CommandSuggestion) is returned
And the suggestion extends or refines the line rather than replacing unrelated intent
```

### Scenario: AI is not called automatically on typing

```gherkin
Given the user is typing normally in the ribbon
When deterministic suggestions are being ranked
Then completeCommandLine is not invoked
And no provider request is made
```

### Scenario: Privacy mode blocks disallowed provider usage

```gherkin
Given privacy mode is local or remote-private only
When completeCommandLine is called
Then the selected provider respects that privacy mode
And prompt text is not sent to a cloud provider without consent
```

### Scenario: AI returns alternatives for ambiguous intent

```gherkin
Given partialLine equals "find logs"
When completeCommandLine is called
Then Right(CommandSuggestion) is returned
And suggestion.alternatives may contain multiple plausible completions
And the user can choose before applying
```

### Scenario: Empty or whitespace line is rejected

```gherkin
Given partialLine is empty
When completeCommandLine is called
Then Left(AIFailure.invalidInput) is returned
```

## Implementation Notes

- This flow is explicit AI assistance, not per-keystroke autocomplete
- It may reuse the same AI service/prompt infrastructure as Ghostwriter
- The prompt should include partial line, shell, OS, cwd, and recent commands
- The UI should allow insert/replace/edit rather than immediately execute

## Related Specs

- L2: [Command Ribbon Component](../L2-contract/component-command-ribbon.md)
- L2: [AI Gateway Service](../L2-contract/service-ai-gateway.md)
- L1: [generateCommand](ai-generate-command.md)
