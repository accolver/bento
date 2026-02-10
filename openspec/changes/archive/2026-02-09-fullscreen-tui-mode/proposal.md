## Why

Bento's semantic blocks interface currently breaks down when running full-screen
TUI applications like Claude Code, OpenCode, vim, htop, or any application that
uses the terminal's alternate screen buffer. These applications rely on
controlling the entire terminal viewport for their UI rendering, cursor
positioning, and real-time updates - capabilities that are incompatible with
Bento's block-by-block output parsing. Without proper TUI mode support, users
cannot use Bento for one of the most common developer workflows: running
AI-assisted coding tools and full-screen terminal applications.

## What Changes

- **TUI Mode Detection**: Automatically detect when an application enters
  alternate screen buffer mode (via DECSET 1049/smcup escape sequences) and
  switches back (rmcup)
- **Dynamic View Switching**: Seamlessly transition between semantic blocks view
  and full-screen xterm view based on TUI mode state
- **Block Suspension**: Pause block detection and output routing during TUI
  mode, resuming when TUI exits
- **TUI Session Blocks**: Create a special block type that represents an entire
  TUI session (command that launched it, duration, exit status) visible in block
  history after TUI exits
- **Full Terminal Passthrough**: During TUI mode, route all input directly to
  terminal without ribbon interception, and render full xterm output without
  parsing
- **Resize Handling**: Ensure TUI applications receive proper resize events when
  device orientation changes or keyboard appears/hides

## Capabilities

### New Capabilities

- `tui-mode-detection`: Escape sequence monitoring to detect alternate screen
  buffer activation/deactivation, application cursor mode, and other TUI-related
  terminal modes
- `tui-view-switching`: Dynamic switching between semantic blocks view and
  full-screen terminal view, including animation, state management, and input
  mode changes
- `tui-session-blocks`: Special block type for representing completed TUI
  sessions in the block history with summary information

### Modified Capabilities

- `semantic-blocks`: Requirements change to handle TUI mode - must pause during
  TUI and create TUI session blocks after exit
- `terminal-emulation`: Requirements change to support full-screen mode with
  proper resize handling and input passthrough

## Impact

### Affected Code

- `lib/features/terminal/data/services/output_router.dart` - Add TUI detection,
  pause/resume routing
- `lib/features/terminal/presentation/screens/terminal_screen.dart` - Dynamic
  view switching logic
- `lib/features/terminal/presentation/providers/terminal_provider.dart` - TUI
  mode state management
- `lib/features/terminal/presentation/providers/block_provider.dart` - TUI
  session block handling
- `lib/features/terminal/domain/entities/block.dart` - Add TUI session block
  type
- `lib/features/terminal/presentation/widgets/terminal_view.dart` - Full-screen
  mode support

### APIs

- New provider: `TuiModeProvider` exposing current TUI mode state
- New entity: `TuiSessionBlock` extending or composing with `TerminalBlock`

### Dependencies

- No new external dependencies; uses existing xterm package which already
  handles escape sequences internally

### Systems

- State management (Riverpod) - new providers for TUI mode
- Database (Drift) - may need schema migration for TUI block type storage
