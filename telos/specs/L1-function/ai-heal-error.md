<!-- telos-metadata
id: L1:function:lib/features/ai/domain/usecases:healError
level: 1
title: healError
parent: L2:contract:service-ai-gateway
-->

# L1: healError

## Purpose

Analyzes a failed command and its error output to suggest a fix, providing both
the corrected command and an explanation of what went wrong.

## Signature

```dart
Future<Either<AIFailure, CommandFix>> healError({
  required String command,
  required String stderr,
  required int exitCode,
  ShellContext? context,
});
```

## Parameters

| Name     | Type          | Description                                   |
| -------- | ------------- | --------------------------------------------- |
| command  | String        | The command that failed                       |
| stderr   | String        | Standard error output from the failed command |
| exitCode | int           | Exit code of the failed command               |
| context  | ShellContext? | Optional shell context for better suggestions |

## Returns

| Type                          | Description                                          |
| ----------------------------- | ---------------------------------------------------- |
| Either<AIFailure, CommandFix> | Right(fix) on success, Left(failure) if no fix found |

## TDD Scenarios

### Scenario: Permission denied - suggest sudo

```gherkin
Given the AI system is ready
When healError is called with command "npm install -g typescript"
And stderr contains "EACCES: permission denied"
And exitCode is 1
Then Right(CommandFix) is returned
And fix.fixedCommand equals "sudo npm install -g typescript"
And fix.fixType equals FixType.addSudo
And fix.explanation contains "permission" and "sudo"
And fix.requiresConfirmation is true
```

### Scenario: Command not found - suggest install

```gherkin
Given the AI system is ready
When healError is called with command "htop"
And stderr contains "command not found: htop"
And exitCode is 127
And context.os is "linux"
Then Right(CommandFix) is returned
And fix.fixedCommand equals "sudo apt install htop" or similar
And fix.fixType equals FixType.installPackage
And fix.explanation contains "not installed"
```

### Scenario: Command not found - macOS

```gherkin
Given the AI system is ready
When healError is called with command "wget https://example.com"
And stderr contains "command not found: wget"
And exitCode is 127
And context.os is "darwin"
Then Right(CommandFix) is returned
And fix.fixedCommand equals "brew install wget" 
And fix.fixType equals FixType.installPackage
```

### Scenario: Directory does not exist

```gherkin
Given the AI system is ready
When healError is called with command "cd /var/log/myapp"
And stderr contains "No such file or directory"
And exitCode is 1
Then Right(CommandFix) is returned
And fix.fixedCommand equals "mkdir -p /var/log/myapp && cd /var/log/myapp"
And fix.fixType equals FixType.createDirectory
```

### Scenario: Syntax error in command

```gherkin
Given the AI system is ready
When healError is called with command "git comit -m 'test'"
And stderr contains "git: 'comit' is not a git command"
And exitCode is 1
Then Right(CommandFix) is returned
And fix.fixedCommand equals "git commit -m 'test'"
And fix.fixType equals FixType.fixSyntax
And fix.explanation contains "typo" or "misspelled"
```

### Scenario: File permission issue

```gherkin
Given the AI system is ready
When healError is called with command "cat /etc/shadow"
And stderr contains "Permission denied"
And exitCode is 1
Then Right(CommandFix) is returned
And fix.fixedCommand equals "sudo cat /etc/shadow"
And fix.fixType equals FixType.addSudo
And fix.requiresConfirmation is true
```

### Scenario: Missing required argument

```gherkin
Given the AI system is ready
When healError is called with command "grep pattern"
And stderr contains "No such file or directory" or "missing file operand"
And exitCode is 2
Then Right(CommandFix) is returned
And fix.fixType equals FixType.fixArguments
And fix.explanation mentions missing file argument
```

### Scenario: File not found - suggest correct path

```gherkin
Given the AI system is ready
When healError is called with command "cat /var/logs/syslog"
And stderr contains "No such file or directory"
And exitCode is 1
Then Right(CommandFix) is returned
And fix.fixedCommand equals "cat /var/log/syslog"
And fix.fixType equals FixType.fixPath
And fix.explanation mentions correct path
```

### Scenario: No fix available

```gherkin
Given the AI system is ready
When healError is called with command "some-custom-script.sh"
And stderr contains "Custom application error: database connection failed"
And exitCode is 1
Then Left(AIFailure.inferenceError) is returned
And failure message indicates no fix could be determined
```

### Scenario: Empty stderr

```gherkin
Given the AI system is ready
When healError is called with command "false"
And stderr is empty
And exitCode is 1
Then Left(AIFailure.invalidInput) is returned
And failure message indicates insufficient error information
```

### Scenario: Privacy - always use local AI

```gherkin
Given the AI system is ready
And user preference is any setting
When healError is called with any command and stderr
Then only the local AI provider is used
And no data is sent to cloud providers
And fix.provider equals AIProvider.local
```

### Scenario: Dangerous fix requires confirmation

```gherkin
Given the AI system is ready
When healError is called with command "rm important_file"
And stderr contains "Permission denied"
Then Right(CommandFix) is returned
And fix.fixedCommand contains "sudo rm"
And fix.requiresConfirmation is true
```

## Implementation Notes

- ALWAYS use local AI for privacy (stderr may contain sensitive data)
- Use pattern matching for common errors before AI inference
- Timeout: 500ms target for responsive UX
- Cache common error patterns for instant fixes
- Set requiresConfirmation for dangerous operations

## Common Error Patterns (Pre-AI)

```dart
final commonFixes = {
  RegExp(r'EACCES|Permission denied'): FixType.addSudo,
  RegExp(r'command not found'): FixType.installPackage,
  RegExp(r'No such file or directory'): FixType.createDirectory,
  RegExp(r"is not a git command"): FixType.fixSyntax,
};
```

## Prompt Template

```
A command failed. Suggest a fix.

Command: {command}
Exit code: {exitCode}
Error output:
{stderr}

Respond with:
1. Brief explanation of the error (one line)
2. Fixed command

Format:
EXPLANATION: <explanation>
FIXED: <command>
```

## Related Specs

- L2: [AI Gateway Service](../L2-contract/service-ai-gateway.md)
- L3: [Error Recovery](../L3-experience/error-recovery.md)
- L2: [Heal Banner Component](../L2-contract/component-heal-banner.md)
