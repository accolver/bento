// @telos L1:function:lib/features/home/presentation/screens:home_screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../connections/domain/entities/saved_connection.dart';
import '../../../connections/presentation/providers/saved_connections_provider.dart';

/// Home screen showing saved connections and quick actions.
///
/// This is the main entry point of the app, displaying:
/// - List of favorite/recent connections
/// - Quick connect button
/// - Navigation to full connection list
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(savedConnectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(Routes.settings),
          ),
        ],
      ),
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error),
        data: (connections) => _buildContent(context, ref, connections),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.sshConnect),
        icon: const Icon(Icons.add),
        label: const Text('New Connection'),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading connections',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => ref.invalidate(savedConnectionsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<SavedConnection> connections,
  ) {
    if (connections.isEmpty) {
      return _buildEmptyState(context);
    }

    final favorites = connections.where((c) => c.isFavorite).toList();
    final recent = connections
        .where((c) => !c.isFavorite && c.lastUsedAt != null)
        .toList()
      ..sort((a, b) =>
          (b.lastUsedAt ?? DateTime(0)).compareTo(a.lastUsedAt ?? DateTime(0)));

    return ListView(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      children: [
        // Header with terminal icon
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.terminal,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Mobile Terminal',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),

        // Favorites section
        if (favorites.isNotEmpty) ...[
          _SectionHeader(
            title: 'Favorites',
            icon: Icons.star,
            action: TextButton(
              onPressed: () => context.push(Routes.sshConnect),
              child: const Text('See All'),
            ),
          ),
          ...favorites.take(3).map(
                (c) => _ConnectionTile(
                  connection: c,
                  onTap: () => _quickConnect(context, ref, c),
                ),
              ),
        ],

        // Recent section
        if (recent.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent',
            icon: Icons.history,
            action: recent.length > 5
                ? TextButton(
                    onPressed: () => context.push(Routes.sshConnect),
                    child: const Text('See All'),
                  )
                : null,
          ),
          ...recent.take(5).map(
                (c) => _ConnectionTile(
                  connection: c,
                  onTap: () => _quickConnect(context, ref, c),
                ),
              ),
        ],

        // All connections link
        if (connections.length >
            (favorites.length + recent.take(5).length)) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list),
            title: Text('All Connections (${connections.length})'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.sshConnect),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terminal,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Bento',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your mobile SSH terminal',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tap the button below to create your first connection',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _quickConnect(
      BuildContext context, WidgetRef ref, SavedConnection connection) {
    // Navigate to SSH connect with this connection pre-selected
    // For now, just go to the SSH connect screen
    // TODO: Implement direct quick connect
    context.push(Routes.sshConnect);
  }
}

/// Section header with icon and optional action.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Compact tile for displaying a connection.
class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.connection,
    required this.onTap,
  });

  final SavedConnection connection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: connection.color != null
            ? Color(int.parse(connection.color!, radix: 16))
            : Theme.of(context).colorScheme.primaryContainer,
        radius: 20,
        child: Icon(
          Icons.computer,
          size: 20,
          color: connection.color != null
              ? Colors.white
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(connection.name),
      subtitle: Text(connection.displayString),
      trailing: connection.isFavorite
          ? const Icon(Icons.star, color: Colors.amber, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
