// @telos L1:function:lib/features/session/presentation/providers:session_controller

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../connections/domain/entities/saved_connection.dart';
import '../../../terminal/domain/entities/ssh_connection_config.dart';
import '../../../terminal/presentation/providers/view_mode_provider.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/session_status.dart';
import 'session_list_state.dart';

part 'session_list_controller.g.dart';

const _uuid = Uuid();

/// Manages the state of multiple terminal sessions.
///
/// Provides methods for creating, closing, switching, and updating sessions.
/// Uses Riverpod for reactive state management.
@Riverpod(keepAlive: true)
class SessionListController extends _$SessionListController {
  @override
  SessionListState build() {
    return const SessionListState();
  }

  /// Creates a new session with the given connection config.
  ///
  /// The new session becomes the active session.
  /// If no name is provided, uses the host from the connection config.
  /// If [savedConnection] is provided, the session will be linked to it
  /// and the user's preferred view mode will be restored.
  ///
  /// Returns the ID of the newly created session.
  String createSession({
    required SSHConnectionConfig config,
    String? name,
    SavedConnection? savedConnection,
  }) {
    final sessionId = _uuid.v4();
    final now = DateTime.now();

    final session = Session(
      id: sessionId,
      name: name ?? config.host,
      connectionConfig: config,
      status: SessionStatus.connecting,
      createdAt: now,
      lastAccessedAt: now,
      savedConnectionId: savedConnection?.id,
    );

    state = state.copyWith(
      sessions: [...state.sessions, session],
      activeSessionId: sessionId,
    );

    // Load the saved view mode preference for this connection
    if (savedConnection != null) {
      ref.read(viewModeControllerProvider.notifier).loadFromConnection(
            savedConnection.id,
            savedConnection.preferredViewMode,
          );
    }

    return sessionId;
  }

  /// Closes and removes a session by ID.
  ///
  /// If the closed session was active, the next or previous session
  /// becomes active. If no sessions remain, activeSessionId becomes null.
  void closeSession(String sessionId) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    // Get the session being closed to check if it was a saved connection
    final closingSession = state.sessions[sessionIndex];
    final newSessions = state.sessions.where((s) => s.id != sessionId).toList();

    String? newActiveId = state.activeSessionId;

    // If we closed the active session, select a new one
    if (state.activeSessionId == sessionId) {
      if (newSessions.isEmpty) {
        newActiveId = null;
        // Clear view mode connection tracking when no sessions remain
        ref.read(viewModeControllerProvider.notifier).clearConnection();
      } else if (sessionIndex < newSessions.length) {
        // Select the session at the same index (next session)
        newActiveId = newSessions[sessionIndex].id;
      } else {
        // Select the last session (previous session)
        newActiveId = newSessions.last.id;
      }

      // If switching to a different session, update view mode tracking
      if (newActiveId != null) {
        final newActiveSession =
            newSessions.firstWhere((s) => s.id == newActiveId);
        if (newActiveSession.savedConnectionId != null) {
          // Note: We don't have the SavedConnection here, so we just update
          // the connection ID. The view mode state is already in memory.
          // A full implementation would reload from database if needed.
        } else {
          ref.read(viewModeControllerProvider.notifier).clearConnection();
        }
      }
    }

    state = state.copyWith(
      sessions: newSessions,
      activeSessionId: newActiveId,
    );
  }

  /// Sets the active session.
  ///
  /// Also resets the unread count for the newly active session.
  /// Does nothing if the session ID doesn't exist.
  void setActiveSession(String sessionId) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    // Reset unread count for the new active session
    final updatedSessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(
          unreadCount: 0,
          lastAccessedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();

    state = state.copyWith(
      sessions: updatedSessions,
      activeSessionId: sessionId,
    );
  }

  /// Updates the status of a session.
  ///
  /// Does nothing if the session ID doesn't exist.
  void updateSessionStatus(String sessionId, SessionStatus status) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final updatedSessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(status: status);
      }
      return s;
    }).toList();

    state = state.copyWith(sessions: updatedSessions);
  }

  /// Increments the unread count for a session by 1.
  ///
  /// Does nothing if the session ID doesn't exist.
  void incrementUnread(String sessionId) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final updatedSessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(unreadCount: s.unreadCount + 1);
      }
      return s;
    }).toList();

    state = state.copyWith(sessions: updatedSessions);
  }

  /// Resets the unread count for a session to 0.
  ///
  /// Does nothing if the session ID doesn't exist.
  void resetUnread(String sessionId) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final updatedSessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(unreadCount: 0);
      }
      return s;
    }).toList();

    state = state.copyWith(sessions: updatedSessions);
  }

  /// Sets whether a command is running in a session.
  ///
  /// Does nothing if the session ID doesn't exist.
  void setRunningCommand(String sessionId, bool isRunning) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final updatedSessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(hasRunningCommand: isRunning);
      }
      return s;
    }).toList();

    state = state.copyWith(sessions: updatedSessions);
  }

  /// Reorders sessions by moving a session from oldIndex to newIndex.
  void reorderSessions(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.sessions.length ||
        newIndex < 0 ||
        newIndex >= state.sessions.length) {
      return;
    }

    final sessions = List<Session>.from(state.sessions);
    final session = sessions.removeAt(oldIndex);

    // Adjust newIndex if needed after removal
    final adjustedIndex = oldIndex < newIndex ? newIndex : newIndex;
    sessions.insert(adjustedIndex, session);

    state = state.copyWith(sessions: sessions);
  }

  /// Gets a session by ID.
  ///
  /// Returns null if the session doesn't exist.
  Session? getSession(String sessionId) {
    try {
      return state.sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return null;
    }
  }

  /// Updates the lastAccessedAt timestamp for a session.
  void touchSession(String sessionId) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final updatedSessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(lastAccessedAt: DateTime.now());
      }
      return s;
    }).toList();

    state = state.copyWith(sessions: updatedSessions);
  }

  /// Updates the name of a session.
  void renameSession(String sessionId, String newName) {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final updatedSessions = state.sessions.map((s) {
      if (s.id == sessionId) {
        return s.copyWith(name: newName);
      }
      return s;
    }).toList();

    state = state.copyWith(sessions: updatedSessions);
  }
}
