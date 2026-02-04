# Proposal: Command Ribbon (Basic)

## Why

Mobile keyboards are inefficient for CLI input. The Command Ribbon provides
intelligent shortcuts above the keyboard - showing recent commands, completions,
and quick symbols. This reduces keystrokes by enabling tap-to-insert for common
patterns, achieving the 50% keystroke reduction goal.

## What Changes

- Create CommandRibbon widget positioned above keyboard
- Implement history-based command suggestions
- Add tap-to-insert functionality
- Show recent commands when input is empty
- Filter suggestions dynamically as user types
- Add symbol quick-access row (|, >, <, &, etc.)
- Implement horizontal scrolling for overflow
- Add visual feedback on selection

## Capabilities

### New Capabilities

- `command-ribbon`: Suggestion strip widget
- `history-suggestions`: Recent command completions
- `symbol-row`: Quick access to shell symbols
- `tap-insert`: One-tap command insertion

## Impact

- `lib/features/terminal/presentation/widgets/command_ribbon.dart`: Ribbon
  widget
- `lib/features/terminal/presentation/providers/ribbon_provider.dart`: Ribbon
  state
- `lib/database/tables/command_history.dart`: History table

## Dependencies

- `scaffold-flutter-project`: Requires Flutter project structure
- `terminal-emulation`: Integrates with terminal input

## Phase

**Phase 1 - MVP** (Weeks 11-12)

## Priority

**P0 - Must Have**
