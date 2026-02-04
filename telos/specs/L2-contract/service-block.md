<!-- telos-metadata
id: L2:contract:service-block
level: 2
title: Block Service
parent: L3:experience:incident-response
children:
  - L1:function:lib/features/terminal/domain/usecases:parseTappableElements
-->

# L2: Block Service

## Overview

The Block Service manages Semantic Blocks - the discrete units of command/output
that form Bento's core UI paradigm. It handles block creation, persistence,
search, and lifecycle management.

## Interface

### BlockService

```dart
abstract class BlockService {
  /// Create a new block for a command execution
  Future<Block> createBlock({
    required String sessionId,
    required String command,
  });
  
  /// Update block with output data
  Future<void> appendOutput(String blockId, String output);
  
  /// Update block with stderr data
  Future<void> appendStderr(String blockId, String stderr);
  
  /// Complete a block with exit code
  Future<void> completeBlock(String blockId, int exitCode);
  
  /// Get all blocks for a session
  Future<List<Block>> getBlocksForSession(String sessionId);
  
  /// Watch blocks for a session (live updates)
  Stream<List<Block>> watchBlocksForSession(String sessionId);
  
  /// Search blocks by content
  Future<List<Block>> searchBlocks(String query, {String? sessionId});
  
  /// Search within a single block
  List<SearchMatch> searchInBlock(String blockId, String query);
  
  /// Toggle block collapsed state
  Future<void> toggleCollapsed(String blockId);
  
  /// Toggle block pinned state
  Future<void> togglePinned(String blockId);
  
  /// Set AI summary for a block
  Future<void> setSummary(String blockId, String summary);
  
  /// Delete a block
  Future<void> deleteBlock(String blockId);
  
  /// Delete all blocks for a session
  Future<void> clearSession(String sessionId);
  
  /// Parse tappable elements in block output
  List<TappableElement> parseTappableElements(String output);
}
```

### Data Models

```dart
@freezed
class Block with _$Block {
  const factory Block({
    required String id,
    required String sessionId,
    required String command,
    required DateTime timestamp,
    required BlockStatus status,
    required String output,
    String? stderr,
    int? exitCode,
    Duration? executionTime,
    String? aiSummary,
    @Default(false) bool isPinned,
    @Default(false) bool isCollapsed,
    List<TappableElement>? tappableElements,
  }) = _Block;
}

enum BlockStatus {
  running,
  success,
  failed,
  cancelled,
}

@freezed
class TappableElement with _$TappableElement {
  const factory TappableElement({
    required TappableType type,
    required String value,
    required int startOffset,
    required int endOffset,
  }) = _TappableElement;
}

enum TappableType {
  ipAddress,
  filePath,
  url,
  json,
  email,
  uuid,
  gitCommit,
}

@freezed
class SearchMatch with _$SearchMatch {
  const factory SearchMatch({
    required int lineNumber,
    required int startOffset,
    required int endOffset,
    required String matchedText,
    required String lineContent,
  }) = _SearchMatch;
}
```

## Behavior

### Block Creation

1. Generate unique block ID
2. Record command and timestamp
3. Set status to `running`
4. Persist to database
5. Return block for UI rendering

### Output Handling

- Append output in chunks as received from terminal
- Parse tappable elements on each update (debounced)
- Trigger AI summarization when block completes (if output > 20 lines)

### Block States

| Status      | Visual              | Trigger         |
| ----------- | ------------------- | --------------- |
| `running`   | Pulsing blue border | Block created   |
| `success`   | Green left border   | Exit code 0     |
| `failed`    | Red left border     | Exit code != 0  |
| `cancelled` | Yellow left border  | SIGINT received |

### Auto-Summarization

- Triggered when output exceeds 20 lines
- Uses local AI for privacy
- Summary stored with block
- Shown in collapsed view

### Tappable Element Detection

Patterns detected:

- IPv4/IPv6 addresses
- File paths (Unix-style)
- URLs (http/https)
- JSON objects
- Email addresses
- UUIDs
- Git commit hashes (7+ hex chars)

## Persistence

### SQLite Schema

```sql
CREATE TABLE blocks (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  command TEXT NOT NULL,
  output TEXT NOT NULL,
  stderr TEXT,
  exit_code INTEGER,
  status INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  execution_time INTEGER,
  ai_summary TEXT,
  is_pinned INTEGER DEFAULT 0,
  is_collapsed INTEGER DEFAULT 0,
  tappable_elements TEXT,  -- JSON
  FOREIGN KEY (session_id) REFERENCES sessions(id)
);

CREATE INDEX idx_blocks_session ON blocks(session_id);
CREATE INDEX idx_blocks_timestamp ON blocks(timestamp);
```

## Error Handling

| Error                | Behavior                       |
| -------------------- | ------------------------------ |
| Database write fails | Retry with backoff, log error  |
| Block not found      | Return empty/null, log warning |
| Search timeout       | Return partial results         |

## Related Specs

- L3: [Incident Response](../L3-experience/incident-response.md)
- L3: [Error Recovery](../L3-experience/error-recovery.md)
- L2: [Block Widget](component-block-widget.md)
- L1: [To be defined - Block parsing functions]
- L1: [To be defined - Tappable element parser]
