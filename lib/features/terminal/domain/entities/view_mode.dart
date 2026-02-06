// @telos L1:function:lib/features/terminal/domain/entities:view_mode

/// User-selectable view mode for the terminal interface.
///
/// This is distinct from [TerminalMode] which handles automatic mode switching
/// (e.g., TUI detection). ViewMode represents the user's preference for how
/// they want to see the terminal when not in TUI mode.
enum ViewMode {
  /// Split screen view - blocks at top, terminal input at bottom (default).
  ///
  /// This shows semantic blocks for command history with a fixed-height
  /// terminal input area at the bottom.
  split,

  /// Full-screen terminal view.
  ///
  /// Shows only the classic terminal interface, taking the full screen.
  /// Useful when users prefer traditional terminal experience.
  fullTerminal,

  /// Full-screen blocks view.
  ///
  /// Shows only the semantic blocks list, taking the full screen.
  /// Terminal input is hidden - users can tap blocks to rerun commands.
  fullBlocks,
}

/// Extension methods for [ViewMode].
extension ViewModeExtension on ViewMode {
  /// Returns a human-readable label for this mode.
  String get label {
    switch (this) {
      case ViewMode.split:
        return 'Split';
      case ViewMode.fullTerminal:
        return 'Terminal';
      case ViewMode.fullBlocks:
        return 'Blocks';
    }
  }

  /// Returns a description of this mode.
  String get description {
    switch (this) {
      case ViewMode.split:
        return 'Blocks + terminal input';
      case ViewMode.fullTerminal:
        return 'Full-screen terminal';
      case ViewMode.fullBlocks:
        return 'Full-screen blocks';
    }
  }

  /// Returns the icon for this mode.
  String get iconName {
    switch (this) {
      case ViewMode.split:
        return 'vertical_split';
      case ViewMode.fullTerminal:
        return 'terminal';
      case ViewMode.fullBlocks:
        return 'view_agenda';
    }
  }

  /// Whether this mode shows the terminal input area.
  bool get showsTerminal =>
      this == ViewMode.split || this == ViewMode.fullTerminal;

  /// Whether this mode shows the blocks list.
  bool get showsBlocks => this == ViewMode.split || this == ViewMode.fullBlocks;
}
