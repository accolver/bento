// @telos L1:function:lib/features/terminal/presentation/providers:view_mode_provider

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/view_mode.dart';

part 'view_mode_provider.g.dart';

/// Manages the user's selected view mode preference.
///
/// This provider tracks the user's preferred view mode (split, fullTerminal, fullBlocks).
/// The view mode is independent of TUI detection - when a TUI app is running,
/// the terminal automatically switches to full-screen regardless of this setting.
///
/// When the TUI app exits, the terminal returns to the user's selected view mode.
@Riverpod(keepAlive: true)
class ViewModeController extends _$ViewModeController {
  @override
  ViewMode build() {
    // Default to split view
    return ViewMode.split;
  }

  /// Sets the view mode.
  void setViewMode(ViewMode mode) {
    state = mode;
  }

  /// Cycles to the next view mode.
  ///
  /// Useful for single-button toggle: split -> fullTerminal -> fullBlocks -> split
  void cycleViewMode() {
    switch (state) {
      case ViewMode.split:
        state = ViewMode.fullTerminal;
      case ViewMode.fullTerminal:
        state = ViewMode.fullBlocks;
      case ViewMode.fullBlocks:
        state = ViewMode.split;
    }
  }
}
