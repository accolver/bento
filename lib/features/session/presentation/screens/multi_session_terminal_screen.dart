// @telos L2:contract:service-session

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../terminal/domain/entities/ssh_connection_config.dart';
import '../../../terminal/presentation/screens/terminal_screen.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/session_status.dart';
import '../providers/session_list_controller.dart';
import '../widgets/session_tab_bar.dart';

/// Multi-session terminal screen with tab bar for switching between sessions.
///
/// This screen manages multiple terminal sessions, displaying a tab bar
/// at the top and the active session's terminal below.
class MultiSessionTerminalScreen extends ConsumerStatefulWidget {
  const MultiSessionTerminalScreen({
    this.initialConfig,
    this.initialName,
    super.key,
  });

  /// Initial connection config to create a session with on first load.
  final SSHConnectionConfig? initialConfig;

  /// Initial session name.
  final String? initialName;

  @override
  ConsumerState<MultiSessionTerminalScreen> createState() =>
      _MultiSessionTerminalScreenState();
}

class _MultiSessionTerminalScreenState
    extends ConsumerState<MultiSessionTerminalScreen> {
  @override
  void initState() {
    super.initState();
    // Create initial session if config provided and no sessions exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSession();
    });
  }

  void _initializeSession() {
    final sessionState = ref.read(sessionListControllerProvider);

    // If we have an initial config and no sessions, create one
    if (widget.initialConfig != null && sessionState.sessions.isEmpty) {
      ref.read(sessionListControllerProvider.notifier).createSession(
            config: widget.initialConfig!,
            name: widget.initialName,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionListControllerProvider);
    final activeSession = sessionState.activeSession;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Session tab bar
            SessionTabBar(
              sessions: sessionState.sessions,
              activeSessionId: sessionState.activeSessionId,
              onTabSelected: _handleTabSelected,
              onTabClose: _handleTabClose,
              onAddTap: _handleAddSession,
            ),

            // Active session terminal (or empty state)
            Expanded(
              child: activeSession != null
                  ? _SessionTerminalView(
                      key: ValueKey(activeSession.id),
                      session: activeSession,
                    )
                  : _EmptySessionState(onAddSession: _handleAddSession),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTabSelected(String sessionId) {
    ref
        .read(sessionListControllerProvider.notifier)
        .setActiveSession(sessionId);
  }

  void _handleTabClose(String sessionId) {
    final session =
        ref.read(sessionListControllerProvider.notifier).getSession(sessionId);

    // If session has running command, show confirmation
    if (session?.hasRunningCommand ?? false) {
      _showCloseConfirmation(sessionId);
    } else {
      ref.read(sessionListControllerProvider.notifier).closeSession(sessionId);
    }
  }

  Future<void> _showCloseConfirmation(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Session?'),
        content: const Text(
          'A command is still running. Close anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(sessionListControllerProvider.notifier).closeSession(sessionId);
    }
  }

  void _handleAddSession() {
    // Navigate to SSH connect screen to create a new session
    context.push(Routes.sshConnect);
  }
}

/// Terminal view for a specific session.
///
/// This wraps the existing TerminalScreen with session-specific state management.
/// In a full implementation, each session would have its own terminal instance.
class _SessionTerminalView extends ConsumerStatefulWidget {
  const _SessionTerminalView({
    required this.session,
    super.key,
  });

  final Session session;

  @override
  ConsumerState<_SessionTerminalView> createState() =>
      _SessionTerminalViewState();
}

class _SessionTerminalViewState extends ConsumerState<_SessionTerminalView> {
  @override
  void initState() {
    super.initState();
    // Mark session as connected when terminal view is created
    // In a real implementation, this would happen after SSH connection succeeds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sessionListControllerProvider.notifier)
          .updateSessionStatus(widget.session.id, SessionStatus.connected);
    });
  }

  @override
  Widget build(BuildContext context) {
    // For now, just render the existing terminal screen
    // The session ID could be used to manage separate terminal instances
    return TerminalScreen(
      title: widget.session.displayName,
    );
  }
}

/// Empty state when no sessions exist.
class _EmptySessionState extends StatelessWidget {
  const _EmptySessionState({
    required this.onAddSession,
  });

  final VoidCallback onAddSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Sessions',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to connect to a server',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddSession,
            icon: const Icon(Icons.add),
            label: const Text('New Session'),
          ),
        ],
      ),
    );
  }
}
