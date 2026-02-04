<!-- telos-metadata
id: L2:contract:service-snippet
level: 2
title: Snippet Service
parent: L3:experience:mobile-vibe-coding
children:
  - L1:function:lib/features/snippets/domain/usecases:renderSnippet
-->

# L2: Snippet Service

## Overview

The Snippet Service manages saved command templates with variable substitution,
enabling users to quickly execute complex commands with customizable parameters.

## Interface

### SnippetService

```dart
abstract class SnippetService {
  /// Create a new snippet
  Future<Either<SnippetFailure, Snippet>> createSnippet(SnippetConfig config);
  
  /// Update an existing snippet
  Future<Either<SnippetFailure, Snippet>> updateSnippet(
    String snippetId, 
    SnippetConfig config,
  );
  
  /// Delete a snippet
  Future<Either<SnippetFailure, void>> deleteSnippet(String snippetId);
  
  /// Get a snippet by ID
  Future<Either<SnippetFailure, Snippet>> getSnippet(String snippetId);
  
  /// Get all snippets
  Future<List<Snippet>> getAllSnippets();
  
  /// Watch all snippets (live updates)
  Stream<List<Snippet>> watchSnippets();
  
  /// Search snippets by name, command, or tags
  Future<List<Snippet>> searchSnippets(String query);
  
  /// Get snippets by tag
  Future<List<Snippet>> getSnippetsByTag(String tag);
  
  /// Get most used snippets
  Future<List<Snippet>> getMostUsedSnippets({int limit = 10});
  
  /// Get recently used snippets
  Future<List<Snippet>> getRecentSnippets({int limit = 5});
  
  /// Render a snippet with variable values
  Either<SnippetFailure, String> renderSnippet(
    Snippet snippet,
    Map<String, String> variables,
  );
  
  /// Execute a snippet in a session
  Future<Either<SnippetFailure, void>> executeSnippet({
    required String snippetId,
    required String sessionId,
    required Map<String, String> variables,
  });
  
  /// Create snippet from existing command
  Future<Either<SnippetFailure, Snippet>> createFromCommand(
    String command, {
    String? name,
    List<String>? tags,
  });
  
  /// Get all unique tags
  Future<List<String>> getAllTags();
}
```

### Data Models

```dart
@freezed
class Snippet with _$Snippet {
  const factory Snippet({
    required String id,
    required String name,
    required String command,
    String? description,
    required List<SnippetVariable> variables,
    List<String>? tags,
    @Default(0) int useCount,
    required DateTime createdAt,
    DateTime? lastUsedAt,
  }) = _Snippet;
}

@freezed
class SnippetConfig with _$SnippetConfig {
  const factory SnippetConfig({
    required String name,
    required String command,
    String? description,
    List<SnippetVariable>? variables,
    List<String>? tags,
  }) = _SnippetConfig;
}

@freezed
class SnippetVariable with _$SnippetVariable {
  const factory SnippetVariable({
    required String name,
    String? description,
    String? defaultValue,
    @Default(false) bool required,
    VariableType? type,
    List<String>? options,  // For dropdown selection
  }) = _SnippetVariable;
}

enum VariableType {
  text,
  number,
  path,
  select,  // Use options list
}

@freezed
class SnippetFailure with _$SnippetFailure {
  const factory SnippetFailure.notFound() = _NotFound;
  const factory SnippetFailure.duplicateName() = _DuplicateName;
  const factory SnippetFailure.invalidTemplate(String message) = _InvalidTemplate;
  const factory SnippetFailure.missingVariable(String variableName) = _MissingVariable;
  const factory SnippetFailure.sessionNotFound() = _SessionNotFound;
  const factory SnippetFailure.storageError(String message) = _StorageError;
}
```

## Behavior

### Variable Syntax

Variables are defined using `${variableName}` syntax in the command template:

```
kubectl set image deployment/${deployment} ${container}=${image}:${tag}
```

### Variable Extraction

When creating from command or parsing template:

1. Find all `${...}` patterns
2. Extract variable names
3. Create `SnippetVariable` for each unique name
4. User can then set defaults, descriptions, and required flags

### Rendering

1. Validate all required variables have values
2. Replace `${name}` with provided values
3. Return rendered command string
4. If variable missing, return `SnippetFailure.missingVariable()`

### Execution Flow

1. Render snippet with provided variables
2. Get session from SessionService
3. Send rendered command as input
4. Increment useCount, update lastUsedAt

### Smart Suggestions

When creating snippet from command:

- Detect common patterns (paths, IPs, names)
- Suggest variable extraction points
- Auto-generate sensible variable names

## Persistence

### SQLite Schema

```sql
CREATE TABLE snippets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  command TEXT NOT NULL,
  description TEXT,
  variables TEXT NOT NULL,  -- JSON array
  tags TEXT,  -- JSON array
  use_count INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  last_used_at INTEGER
);

CREATE INDEX idx_snippets_name ON snippets(name);
CREATE INDEX idx_snippets_use_count ON snippets(use_count DESC);
```

## Example Snippets

```yaml
# Git workflow
- name: "Quick Commit"
  command: "git add -A && git commit -m '${message}' && git push"
  variables:
    - name: message
      description: "Commit message"
      required: true

# Kubernetes
- name: "Pod Logs"
  command: "kubectl logs -f ${pod} -n ${namespace} --tail=${lines}"
  variables:
    - name: pod
      required: true
    - name: namespace
      default: "default"
    - name: lines
      default: "100"
      type: number

# Docker
- name: "Docker Exec"
  command: "docker exec -it ${container} ${shell}"
  variables:
    - name: container
      required: true
    - name: shell
      default: "/bin/bash"
      type: select
      options: ["/bin/bash", "/bin/sh", "/bin/zsh"]
```

## Related Specs

- L3: [Mobile Vibe Coding](../L3-experience/mobile-vibe-coding.md)
- L2: [Component Snippet Picker](component-snippet-picker.md)
- L1: [To be defined - Template parser]
- L1: [To be defined - Variable renderer]
