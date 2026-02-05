// @telos L1:function:lib/features/terminal/domain/entities:terminal_mode

/// Display mode for the terminal interface.
///
/// The terminal can operate in three modes:
/// - [blocks]: Semantic blocks view with command/output grouping (default)
/// - [tui]: Full-screen terminal for TUI applications (vim, htop, Claude Code, etc.)
/// - [classic]: Traditional continuous terminal output without blocks
enum TerminalMode {
  /// Semantic blocks mode - commands and output grouped into collapsible blocks.
  ///
  /// This is the default mode when [TerminalConfig.enableSemanticBlocks] is true.
  /// Provides structured navigation and search through command history.
  blocks,

  /// TUI (Terminal User Interface) mode - full-screen terminal view.
  ///
  /// Activated automatically when a TUI application enters alternate screen
  /// buffer mode (smcup/DECSET 1049). Examples: vim, htop, less, Claude Code.
  /// In this mode, the terminal occupies the full screen and block detection
  /// is paused to allow proper TUI rendering.
  tui,

  /// Classic terminal mode - continuous output without block grouping.
  ///
  /// This mode is used when [TerminalConfig.enableSemanticBlocks] is false.
  /// Provides traditional terminal experience without semantic structuring.
  classic,
}

/// Extension methods for [TerminalMode].
extension TerminalModeExtension on TerminalMode {
  /// Returns true if this mode uses full-screen terminal view.
  bool get isFullScreen =>
      this == TerminalMode.tui || this == TerminalMode.classic;

  /// Returns true if this mode uses semantic blocks.
  bool get usesBlocks => this == TerminalMode.blocks;

  /// Returns true if this mode is the TUI mode.
  bool get isTui => this == TerminalMode.tui;

  /// Returns a human-readable label for this mode.
  String get label {
    switch (this) {
      case TerminalMode.blocks:
        return 'Semantic Blocks';
      case TerminalMode.tui:
        return 'TUI Mode';
      case TerminalMode.classic:
        return 'Classic Terminal';
    }
  }

  /// Returns a description of this mode.
  String get description {
    switch (this) {
      case TerminalMode.blocks:
        return 'Commands and output organized into collapsible blocks';
      case TerminalMode.tui:
        return 'Full-screen mode for terminal applications';
      case TerminalMode.classic:
        return 'Traditional continuous terminal output';
    }
  }
}
