<!-- telos-metadata
id: L1:function:lib/features/snippets/domain/usecases:renderSnippet
level: 1
title: renderSnippet
parent: L2:contract:service-snippet
-->

# L1: renderSnippet

## Purpose

Renders a snippet template by substituting variables with provided values,
validating required variables are present, and returning the final executable
command.

## Signature

```dart
Either<SnippetFailure, String> renderSnippet(
  Snippet snippet,
  Map<String, String> variables,
);
```

## Parameters

| Name      | Type                | Description                           |
| --------- | ------------------- | ------------------------------------- |
| snippet   | Snippet             | The snippet template to render        |
| variables | Map<String, String> | Variable names mapped to their values |

## Returns

| Type                           | Description                                               |
| ------------------------------ | --------------------------------------------------------- |
| Either<SnippetFailure, String> | Right(renderedCommand) on success, Left(failure) on error |

## TDD Scenarios

### Scenario: Simple variable substitution

```gherkin
Given a snippet with command "echo ${message}"
And snippet has variable "message" with no default
When renderSnippet is called with variables {"message": "Hello World"}
Then Right("echo Hello World") is returned
```

### Scenario: Multiple variables

```gherkin
Given a snippet with command "kubectl get ${resource} -n ${namespace}"
And snippet has variables "resource" and "namespace"
When renderSnippet is called with variables {"resource": "pods", "namespace": "production"}
Then Right("kubectl get pods -n production") is returned
```

### Scenario: Variable with default value used

```gherkin
Given a snippet with command "git checkout ${branch}"
And snippet has variable "branch" with default "main"
When renderSnippet is called with variables {} (empty)
Then Right("git checkout main") is returned
```

### Scenario: Variable with default value overridden

```gherkin
Given a snippet with command "git checkout ${branch}"
And snippet has variable "branch" with default "main"
When renderSnippet is called with variables {"branch": "feature/new"}
Then Right("git checkout feature/new") is returned
```

### Scenario: Missing required variable

```gherkin
Given a snippet with command "docker run ${image}"
And snippet has variable "image" with required=true and no default
When renderSnippet is called with variables {} (empty)
Then Left(SnippetFailure.missingVariable("image")) is returned
```

### Scenario: Multiple missing required variables

```gherkin
Given a snippet with command "scp ${source} ${user}@${host}:${dest}"
And snippet has variables "source", "user", "host", "dest" all required
When renderSnippet is called with variables {"source": "/tmp/file"}
Then Left(SnippetFailure.missingVariable) is returned
And failure indicates first missing variable
```

### Scenario: Empty variable value allowed

```gherkin
Given a snippet with command "grep ${pattern} ${file}"
And snippet has variable "pattern" with required=true
When renderSnippet is called with variables {"pattern": "", "file": "log.txt"}
Then Right("grep  log.txt") is returned
And empty string is valid for required variable
```

### Scenario: Variable in middle of word

```gherkin
Given a snippet with command "docker push myregistry/${image}:${tag}"
When renderSnippet is called with variables {"image": "myapp", "tag": "v1.0"}
Then Right("docker push myregistry/myapp:v1.0") is returned
```

### Scenario: Same variable used multiple times

```gherkin
Given a snippet with command "echo ${name} && echo Hello ${name}"
When renderSnippet is called with variables {"name": "World"}
Then Right("echo World && echo Hello World") is returned
And both occurrences are replaced
```

### Scenario: Undefined variable in template

```gherkin
Given a snippet with command "echo ${undefined_var}"
And snippet.variables does not contain "undefined_var"
When renderSnippet is called with variables {}
Then Left(SnippetFailure.invalidTemplate) is returned
And failure message mentions "undefined_var"
```

### Scenario: Extra variables ignored

```gherkin
Given a snippet with command "echo ${message}"
And snippet has only variable "message"
When renderSnippet is called with variables {"message": "Hi", "extra": "ignored"}
Then Right("echo Hi") is returned
And "extra" variable is silently ignored
```

### Scenario: Special characters in variable value

```gherkin
Given a snippet with command "echo ${message}"
When renderSnippet is called with variables {"message": "Hello $USER"}
Then Right("echo Hello $USER") is returned
And shell variables in value are preserved (not escaped)
```

### Scenario: Quotes in variable value

```gherkin
Given a snippet with command "git commit -m '${message}'"
When renderSnippet is called with variables {"message": "Fix bug in 'parser'"}
Then Right("git commit -m 'Fix bug in 'parser''") is returned
And quotes are not escaped (user responsibility)
```

### Scenario: Newlines in variable value

```gherkin
Given a snippet with command "echo ${message}"
When renderSnippet is called with variables {"message": "line1\nline2"}
Then Right("echo line1\nline2") is returned
And newlines are preserved
```

### Scenario: Variable syntax edge cases

```gherkin
Given a snippet with command "echo $${notavar} and ${var}"
And snippet has variable "var"
When renderSnippet is called with variables {"var": "value"}
Then Right("echo $${notavar} and value") is returned
And "$${" is not treated as variable syntax
```

### Scenario: Unicode in variable names and values

```gherkin
Given a snippet with command "echo ${greeting}"
When renderSnippet is called with variables {"greeting": "你好世界"}
Then Right("echo 你好世界") is returned
```

### Scenario: Whitespace handling

```gherkin
Given a snippet with command "echo ${message}"
When renderSnippet is called with variables {"message": "  spaced  "}
Then Right("echo   spaced  ") is returned
And whitespace is preserved exactly
```

## Implementation Notes

- Use regex to find all `${variableName}` patterns
- Validate all found variables exist in snippet.variables
- Apply defaults before checking required
- Replace all occurrences of each variable
- Do not escape special characters (user controls escaping)
- Return on first error (fail fast)

## Variable Resolution Order

1. Check if variable name exists in snippet.variables definition
2. Look for value in provided variables map
3. If not provided, check for default value
4. If no default and required=true, return failure
5. If no default and required=false, substitute empty string

## Related Specs

- L2: [Snippet Service](../L2-contract/service-snippet.md)
- L3: [Mobile Vibe Coding](../L3-experience/mobile-vibe-coding.md)
- L1: [parseSnippetVariables](snippet-parse-variables.md)
