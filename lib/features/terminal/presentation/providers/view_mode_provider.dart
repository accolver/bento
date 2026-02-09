// @telos L1:function:lib/features/terminal/presentation/providers:view_mode_provider

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../connections/presentation/providers/saved_connections_provider.dart';
import '../../domain/entities/view_mode.dart';

part 'view_mode_provider.g.dart';

/// Manages the user's selected view mode preference.
///
/// This provider tracks the user's preferred view mode (split, fullTerminal, fullBlocks).
/// The view mode is independent of TUI detection - when a TUI app is running,
/// the terminal automatically switches to full-screen regardless of this setting.
///
/// When the TUI app exits, the terminal returns to the user's selected view mode.
///
/// When connected to a saved connection, view mode changes are persisted to the database.
@Riverpod(keepAlive: true)
class ViewModeController extends _$ViewModeController {
  /// The ID of the currently connected saved connection, if any.
  int? _currentConnectionId;

  @override
  ViewMode build() {
    // Default to split view
    return ViewMode.split;
  }

  /// Sets the view mode.
  ///
  /// If connected to a saved connection, the preference is persisted.
  void setViewMode(ViewMode mode) {
    state = mode;
    _persistViewMode(mode);
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
    _persistViewMode(state);
  }

  /// Loads the view mode preference from a saved connection.
  ///
  /// Called when connecting to a saved connection to restore the user's
  /// preferred layout for that connection.
  void loadFromConnection(int connectionId, String preferredViewMode) {
    _currentConnectionId = connectionId;
    state = _parseViewMode(preferredViewMode);
  }

  /// Clears the connection tracking.
  ///
  /// Called when disconnecting from a session.
  void clearConnection() {
    _currentConnectionId = null;
  }

  /// Parses a view mode string to the enum, falling back to split.
  ViewMode _parseViewMode(String value) {
    return ViewMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ViewMode.split,
    );
  }

  /// Persists the view mode to the database if connected to a saved connection.
  void _persistViewMode(ViewMode mode) {
    final connectionId = _currentConnectionId;
    if (connectionId == null) return;

    final repository = ref.read(savedConnectionsRepositoryProvider);
    repository.updateViewModePreference(connectionId, mode.name);
  }
}
