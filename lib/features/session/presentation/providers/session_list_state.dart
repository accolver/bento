// @telos L1:function:lib/features/session/presentation/providers:session_list_state

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/session.dart';

part 'session_list_state.freezed.dart';

/// State for the session list controller.
///
/// Contains all active sessions and tracks which session is currently active.
@freezed
class SessionListState with _$SessionListState {
  const SessionListState._();

  const factory SessionListState({
    /// List of all active sessions in display order.
    @Default([]) List<Session> sessions,

    /// ID of the currently active session, or null if none.
    String? activeSessionId,
  }) = _SessionListState;

  /// Returns the currently active session, or null if none.
  Session? get activeSession {
    if (activeSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == activeSessionId);
    } catch (_) {
      return null;
    }
  }

  /// Returns the index of the active session, or -1 if none.
  int get activeSessionIndex {
    if (activeSessionId == null) return -1;
    return sessions.indexWhere((s) => s.id == activeSessionId);
  }

  /// Returns true if there are any sessions.
  bool get hasSessions => sessions.isNotEmpty;

  /// Returns the number of sessions.
  int get sessionCount => sessions.length;
}
