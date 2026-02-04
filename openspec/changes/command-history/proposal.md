# Proposal: Command History

## Why

Command history is essential for terminal productivity. Users need to recall
previous commands, search through history, and leverage patterns for the
predictive ribbon. Unlike traditional shell history, Bento tracks command
sequences to enable intelligent workflow prediction - knowing that
`kubectl get nodes` is often followed by `kubectl get pods -n production`.

## What Changes

- Define CommandHistory table schema with Drift
- Track command with session context and exit codes
- Store previous command for sequence prediction
- Implement history search with full-text search
- Create history provider for ribbon integration
- Add history browser screen for viewing all commands
- Support history export for backup
- Implement history limits and cleanup policies

## Capabilities

### New Capabilities

- `history-tracking`: Record commands with context
- `history-search`: Full-text search through history
- `sequence-tracking`: Track command sequences
- `history-export`: Export history as JSON/text
- `history-cleanup`: Manage history size limits

## Impact

- `lib/database/tables/command_history.dart`: CommandHistory table
- `lib/database/daos/history_dao.dart`: Data access object
- `lib/features/terminal/domain/entities/history_entry.dart`: History entity
- `lib/features/terminal/presentation/providers/history_provider.dart`: State
- `lib/features/terminal/presentation/screens/history_screen.dart`: Browser UI

## Dependencies

- `block-persistence`: Integrates with block storage
- `session-tabs`: Tracks history per session

## Phase

**Phase 1 - MVP** (Weeks 7-8)

## Priority

**P0 - Must Have**

Core terminal functionality - history powers ribbon predictions and search.
