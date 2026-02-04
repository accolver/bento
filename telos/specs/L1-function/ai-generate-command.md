<!-- telos-metadata
id: L1:function:lib/features/ai/domain/usecases:generateCommand
level: 1
title: generateCommand
parent: L2:contract:service-ai-gateway
-->

# L1: generateCommand

## Purpose

Converts a natural language description into a CLI command using AI (local or
cloud), providing the command, explanation, and confidence score.

## Signature

```dart
Future<Either<AIFailure, CommandSuggestion>> generateCommand({
  required String naturalLanguage,
  required ShellContext context,
  AIProvider? preferredProvider,
});
```

## Parameters

| Name              | Type         | Description                                        |
| ----------------- | ------------ | -------------------------------------------------- |
| naturalLanguage   | String       | User's plain English description of desired action |
| context           | ShellContext | Current shell environment (OS, shell, cwd, etc.)   |
| preferredProvider | AIProvider?  | Force specific AI provider (local/cloud)           |

## Returns

| Type                                 | Description                                          |
| ------------------------------------ | ---------------------------------------------------- |
| Either<AIFailure, CommandSuggestion> | Right(suggestion) on success, Left(failure) on error |

## TDD Scenarios

### Scenario: Simple command generation with local AI

```gherkin
Given the local AI model is loaded
And the user preference is "local only"
When generateCommand is called with naturalLanguage "list all files"
And context has shell "bash" and os "linux"
Then the local AI model processes the request
And Right(CommandSuggestion) is returned
And suggestion.command equals "ls -la"
And suggestion.explanation contains "list" and "files"
And suggestion.confidence is greater than 0.7
And suggestion.provider equals AIProvider.local
```

### Scenario: Complex command with cloud AI

```gherkin
Given the user preference allows cloud AI
And network connectivity is available
When generateCommand is called with naturalLanguage "find all Python files modified in the last week that contain the word 'async'"
And context has shell "zsh" and os "darwin"
Then the request is routed to cloud AI (complexity > threshold)
And Right(CommandSuggestion) is returned
And suggestion.command contains "find" and "-mtime" and "grep"
And suggestion.provider equals AIProvider.openai or AIProvider.anthropic
```

### Scenario: Context-aware command generation

```gherkin
Given the local AI model is loaded
When generateCommand is called with naturalLanguage "show disk usage"
And context has os "darwin"
Then suggestion.command equals "df -h" or similar macOS command
When generateCommand is called with naturalLanguage "show disk usage"
And context has os "linux"
Then suggestion.command equals "df -h" or similar Linux command
```

### Scenario: Command with current directory context

```gherkin
Given the local AI model is loaded
When generateCommand is called with naturalLanguage "delete all node_modules folders"
And context has cwd "/home/user/projects"
Then suggestion.command contains the cwd path or uses relative paths
And suggestion.explanation mentions the current directory
```

### Scenario: Fallback to local when cloud unavailable

```gherkin
Given the user preference allows cloud AI
And network connectivity is unavailable
When generateCommand is called with naturalLanguage "compress this folder"
Then cloud AI request fails
And local AI is used as fallback
And Right(CommandSuggestion) is returned
And suggestion.provider equals AIProvider.local
```

### Scenario: Local model not loaded

```gherkin
Given the local AI model is not loaded
And user preference is "local only"
When generateCommand is called with any naturalLanguage
Then Left(AIFailure.modelNotLoaded) is returned
```

### Scenario: Empty or invalid input

```gherkin
Given the AI system is ready
When generateCommand is called with naturalLanguage ""
Then Left(AIFailure.invalidInput) is returned
And failure message indicates empty input
```

### Scenario: Ambiguous request

```gherkin
Given the AI system is ready
When generateCommand is called with naturalLanguage "do the thing"
Then Right(CommandSuggestion) is returned
And suggestion.confidence is less than 0.5
And suggestion.alternatives contains multiple options
```

### Scenario: Request with dangerous command

```gherkin
Given the AI system is ready
When generateCommand is called with naturalLanguage "delete everything in root"
Then Right(CommandSuggestion) is returned
And suggestion.command may contain "rm -rf /"
And the calling code should check for dangerous patterns separately
```

### Scenario: Shell-specific command

```gherkin
Given the AI system is ready
When generateCommand is called with naturalLanguage "set an environment variable FOO to bar"
And context has shell "bash"
Then suggestion.command equals "export FOO=bar"
When context has shell "fish"
Then suggestion.command equals "set -x FOO bar"
```

### Scenario: Available commands influence suggestion

```gherkin
Given the AI system is ready
When generateCommand is called with naturalLanguage "pretty print this JSON file"
And context.availableCommands contains "jq"
Then suggestion.command uses "jq"
When context.availableCommands does not contain "jq"
Then suggestion.command uses "python -m json.tool" or similar
```

## Implementation Notes

- Use prompt template from AIPromptTemplates.commandGeneration
- Include context in prompt (shell, OS, cwd, available commands)
- Parse response to extract command and explanation
- Calculate confidence based on model's response quality
- Limit naturalLanguage input to 500 characters
- Timeout: 2s for local, 10s for cloud
- Cache recent queries for faster repeated requests

## Prompt Template

```
You are a CLI assistant. Convert the user's request to a shell command.

Context:
- Shell: {context.shell}
- OS: {context.os}
- Current directory: {context.cwd}
- Available commands: {context.availableCommands}

User request: {naturalLanguage}

Respond with ONLY the command, no explanation.
Command:
```

## Related Specs

- L2: [AI Gateway Service](../L2-contract/service-ai-gateway.md)
- L3: [AI Command Assistance](../L3-experience/ai-command-assistance.md)
- L1: [initializeLocalModel](ai-initialize-local-model.md)
