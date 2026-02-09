## Context

Bento's terminal interface supports three view modes: `split`, `fullTerminal`,
and `fullBlocks`. Currently, the `ViewModeController` (Riverpod provider) is
global and non-persistent - it defaults to `split` on every app restart and has
no awareness of which connection the user is working with.

Users frequently prefer different layouts for different servers (e.g., full
blocks for chatty CI servers, full terminal for interactive work). Having to
reconfigure layout every reconnect is frustrating.

The app already stores connection metadata in the `saved_connections` table via
Drift, including per-connection settings like `terminalType` and `color`. This
is the natural place to add layout preferences.

## Goals / Non-Goals

**Goals:**

- Persist the user's last-used view mode per saved connection
- Restore that view mode when reconnecting to a saved connection
- Save view mode changes transparently (no explicit "save" action needed)
- Maintain current default behavior for new/quick connections

**Non-Goals:**

- Syncing layout preferences across devices (future consideration)
- Per-session layout memory (only per-connection)
- Undo/history for layout changes
- Persisting other UI state (scroll position, panel sizes, etc.)

## Decisions

### 1. Storage: Database column vs. SharedPreferences

**Decision**: Add `preferred_view_mode` column to `saved_connections` table.

**Alternatives considered**:

- SharedPreferences with key pattern `bento_connection_view_mode_{id}`: Would
  work but creates orphaned keys when connections are deleted, lacks atomic
  operations with connection data.
- Separate preferences table: Over-engineered for a single field.

**Rationale**: The connection record is the natural owner of this preference.
Using Drift ensures atomicity and automatic cleanup on connection deletion.

### 2. Column type and default

**Decision**: `TEXT` column with default value `'split'`, nullable.

**Rationale**:

- Store enum name as text for readability and forward compatibility
- Default to 'split' (current app default) so existing connections behave
  unchanged
- Nullable to distinguish "user never set this" from "user chose split"

### 3. When to save

**Decision**: Save immediately when view mode changes (no debounce).

**Alternatives considered**:

- Debounced save (300-500ms): Reduces writes but adds complexity
- Save on disconnect: Risk losing preference if app crashes

**Rationale**: View mode changes are infrequent (users don't spam-toggle).
Immediate save is simpler and more reliable.

### 4. Provider architecture

**Decision**: Keep `ViewModeController` as global but add initialization from
connection.

**Alternatives considered**:

- Per-session/per-connection scoped provider: Adds complexity, no clear benefit
  since only one session is active at a time currently.
- Entirely new provider: Unnecessary duplication.

**Rationale**: The current global provider works fine. We just need to:

1. Load the saved preference when a session starts
2. Persist changes back when view mode changes

The session/connection manager will call
`viewModeController.setViewMode(savedConnection.preferredViewMode)` on connect.

### 5. Quick connect handling

**Decision**: Quick connections (not saved) use the current in-memory view mode
(no persistence).

**Rationale**: No connection ID means nowhere to persist. Users can save the
connection to enable preference memory.

## Risks / Trade-offs

| Risk                                                         | Mitigation                                                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| Database migration failure on older app versions             | Migration uses `ALTER TABLE ... ADD COLUMN` which is safe. Column is nullable with default. |
| View mode string doesn't match enum value                    | Use `ViewMode.values.firstWhere()` with fallback to `split`                                 |
| User confusion if saved preference differs from current mode | Only load preference on fresh connect, not when switching tabs                              |
| Increased database writes                                    | View mode changes are rare; impact is negligible                                            |

## Migration Plan

1. Increment `DatabaseConstants.schemaVersion` to 5
2. Add migration case in `database.dart` for version 5
3. Update `SavedConnections` table definition with new column
4. Update `SavedConnection` entity with `preferredViewMode` field
5. Regenerate Drift code
6. Update repository methods to handle the new field
7. Update session initialization to load preference
8. Update view mode controller to persist changes

**Rollback**: Column is additive and optional. Removing it requires another
migration but app continues to work without it.
