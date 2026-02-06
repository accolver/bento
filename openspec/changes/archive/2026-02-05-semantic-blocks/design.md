# Design: Semantic Blocks

## Context

Bento currently uses the xterm package directly in `TerminalView`, which renders
all output as a continuous scroll - the traditional "teletype-on-glass"
experience. Users cannot easily navigate back to previous commands, collapse
verbose output, or distinguish between commands and their outputs.

The terminal feature already has:

- `TerminalController` managing xterm Terminal instances
- SSH integration via `SSHDataSource` that streams output to the terminal
- Drift database (`BentoDatabase`) for persistence
- Clean architecture with domain/data/presentation layers

Semantic Blocks will wrap command/output pairs in discrete, navigable units
without replacing the core xterm rendering - blocks will contain terminal output
rendered by xterm within each block's content area.

## Goals / Non-Goals

**Goals:**

- Create Block entity with immutable data model (freezed)
- Display each command/output as a collapsible, self-contained block
- Show visual status indicators (running, success, failed, cancelled)
- Support block actions: copy command, copy output, collapse/expand
- Persist blocks to SQLite for history across app restarts
- Stream output into blocks in real-time during command execution
- Smooth animations for collapse/expand transitions

**Non-Goals:**

- AI summarization (Phase 2 feature)
- Tappable elements parsing (separate change: tappable-elements)
- Block search (separate change: basic-search)
- Block pinning (can add later)
- Block sharing (can add later)

## Decisions

### 1. Block Detection Strategy

**Decision:** Parse SSH output stream for shell prompt patterns to detect
command boundaries.

**Rationale:** The SSH stream is continuous bytes - we need to identify when a
new command starts. Options considered:

- **Option A: Prompt detection (chosen)** - Detect shell prompts (PS1 patterns
  like `user@host:~$`) to identify command entry points. Most shells emit
  prompts before accepting input.
- **Option B: OSC escape sequences** - Some terminals send OSC codes for
  semantic markup, but this requires server-side configuration.
- **Option C: User explicitly marks blocks** - Too manual, defeats the purpose.

Prompt detection handles 90%+ of cases. We'll use configurable regex patterns
and fall back gracefully if detection fails (append to current block).

### 2. Block State Management

**Decision:** Use Riverpod `StateNotifierProvider` with a `BlockList` class
holding an immutable list of `Block` objects.

**Rationale:** Options considered:

- **Option A: StateNotifier with immutable list (chosen)** - Fits existing
  patterns in the codebase, efficient updates via `copyWith`, good for
  persistence.
- **Option B: Stream-based** - Overkill for UI state; we need random access to
  blocks.
- **Option C: ChangeNotifier** - Less type-safe than Riverpod's approach.

The `BlockListController` will handle:

- Creating new blocks when commands are detected
- Appending output to the current running block
- Updating block status when commands complete
- Persisting to database on changes

### 3. Block Rendering Architecture

**Decision:** Each block renders its output using a constrained xterm `Terminal`
instance per block (for ANSI rendering), with the main `TerminalController`
handling input and routing to the active block.

**Rationale:** Options considered:

- **Option A: xterm per block (chosen)** - Preserves ANSI color/formatting,
  consistent rendering, leverages existing xterm integration.
- **Option B: Plain text with manual ANSI parsing** - Significant work to handle
  all escape sequences correctly.
- **Option C: Rich text with spans** - Loses cursor positioning, complex escape
  sequences.

Each `BlockWidget` will contain a small, read-only `TerminalView` for its
output. Only the current/active block accepts input.

### 4. Database Schema

**Decision:** Add `blocks` table with columns for id, session_id, command,
output (compressed), status, timestamps, and metadata.

```sql
CREATE TABLE blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  command TEXT NOT NULL,
  output BLOB NOT NULL,  -- gzip compressed to save space
  status TEXT NOT NULL,  -- 'running', 'success', 'failed', 'cancelled'
  exit_code INTEGER,
  started_at INTEGER NOT NULL,
  completed_at INTEGER,
  is_collapsed INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);
```

**Rationale:** Storing output as compressed BLOB handles large outputs
efficiently. Sessions table will be added by session-tabs change; we'll use a
default session ID until then.

### 5. Collapse/Expand Animation

**Decision:** Use Flutter's `AnimatedContainer` with `Curves.easeInOut` for
smooth height transitions, showing only header when collapsed.

**Rationale:** Simple, performant, and follows platform conventions. The
collapsed state shows: command text, status indicator, timestamp, and output
line count.

### 6. Integration with Existing Terminal

**Decision:** Replace `TerminalScreen` body with a `BlockListView` that contains
multiple `BlockWidget` items, while keeping the input handling and modifier bar.

**Rationale:** Minimal disruption to existing code. The `ModifierKeysBar`
continues to work - keystrokes go to the active block's input. The screen
structure remains the same but content becomes a scrollable list of blocks.

## Risks / Trade-offs

### Risk 1: Prompt Detection Accuracy

**Risk:** Shell prompts vary wildly; detection may fail for custom prompts.
**Mitigation:**

- Start with common patterns (bash, zsh, fish defaults)
- Make patterns configurable in settings
- Graceful fallback: if no prompt detected, append to current block
- Allow manual block split via UI gesture

### Risk 2: Memory Usage with Many Blocks

**Risk:** Long sessions could accumulate hundreds of blocks, each with a
Terminal instance. **Mitigation:**

- Virtualize the block list (only render visible blocks)
- Dispose Terminal instances for off-screen blocks
- Compress and persist old blocks, lazy-load when scrolled to
- Implement block limit with archival

### Risk 3: Performance During High Output

**Risk:** Commands like `cat large_file.txt` could flood the current block.
**Mitigation:**

- Buffer output and batch-append (every 16ms frame)
- Truncate in-memory output at threshold (100KB), mark as "truncated"
- Full output available from database on demand

### Risk 4: xterm-per-block Overhead

**Risk:** Creating many Terminal instances may be expensive. **Mitigation:**

- Pool and reuse Terminal instances for visible blocks
- Collapsed blocks don't need active Terminal
- Measure performance early and adjust if needed

## Migration Plan

1. **Phase 1: Block Entity & Storage**
   - Add Block entity, BlockStatus enum
   - Add blocks table to database (migration v3)
   - Create BlockRepository for CRUD operations

2. **Phase 2: Block State Management**
   - Add BlockListController provider
   - Integrate with TerminalController output stream
   - Implement prompt detection

3. **Phase 3: Block Widget**
   - Create BlockWidget with header and content
   - Add collapse/expand animation
   - Style by status

4. **Phase 4: Integration**
   - Replace TerminalScreen body with BlockListView
   - Wire input to active block
   - Test with real SSH sessions

**Rollback:** Feature flag (`enableSemanticBlocks`) allows reverting to classic
terminal view if issues arise.

## Open Questions

1. **Session ID before session-tabs:** Should we use a hardcoded "default"
   session ID, or implement a minimal sessions table now?
   - **Tentative decision:** Use hardcoded "default" session; session-tabs will
     migrate existing blocks.

2. **Maximum block output size:** What's the cutoff before truncating in-memory?
   - **Tentative decision:** 100KB in memory, full in database.

3. **Prompt pattern configuration:** Where should users configure custom
   prompts?
   - **Tentative decision:** Settings screen, with sensible defaults.
