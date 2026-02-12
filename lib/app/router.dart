// @telos L1:function:lib/app:router

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/home/presentation/screens/home_screen.dart';
import '../features/session/presentation/screens/multi_session_terminal_screen.dart';
import '../features/terminal/presentation/screens/ssh_connect_screen.dart';
import '../features/terminal/presentation/screens/terminal_screen.dart';

part 'router.g.dart';

/// Route paths for the application.
abstract class Routes {
  Routes._();

  static const String home = '/';
  static const String connections = '/connections';
  static const String settings = '/settings';
  static const String sessions = '/sessions';
  static const String terminal = '/terminal/:id';
  static const String sshConnect = '/ssh-connect';

  /// Generate terminal route with connection ID.
  static String terminalPath(String connectionId) => '/terminal/$connectionId';
}

/// Provides the application router configuration.
@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.connections,
        name: 'connections',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Connections'),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Settings'),
      ),
      GoRoute(
        path: Routes.sessions,
        name: 'sessions',
        builder: (context, state) => const MultiSessionTerminalScreen(),
      ),
      GoRoute(
        path: Routes.terminal,
        name: 'terminal',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TerminalScreen(
            sessionId: id,
            title: 'Terminal: $id',
          );
        },
      ),
      GoRoute(
        path: Routes.sshConnect,
        name: 'ssh-connect',
        builder: (context, state) => const SSHConnectScreen(),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
}

/// Placeholder screen used during initial scaffold.
///
/// Will be replaced by actual feature screens.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terminal,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Bento', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Mobile Terminal',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go(Routes.sshConnect),
              icon: const Icon(Icons.login),
              label: const Text('SSH Connect'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.terminalPath('demo')),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Local Terminal Demo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when navigation fails.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
