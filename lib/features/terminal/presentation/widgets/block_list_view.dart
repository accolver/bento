// @telos L1:function:lib/features/terminal/presentation/widgets:block_list_view

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/block_provider.dart';
import 'block_widget.dart';

/// Displays a virtualized list of terminal blocks.
///
/// Features:
/// - Efficient rendering with ListView.builder
/// - Auto-scrolls to new blocks at bottom
/// - Empty state when no blocks
class BlockListView extends ConsumerStatefulWidget {
  const BlockListView({
    super.key,
    this.onRerunCommand,
  });

  /// Callback when user wants to re-run a command.
  final void Function(String command)? onRerunCommand;

  @override
  ConsumerState<BlockListView> createState() => _BlockListViewState();
}

class _BlockListViewState extends ConsumerState<BlockListView> {
  final ScrollController _scrollController = ScrollController();
  int _lastBlockCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockListControllerProvider);
    final controller = ref.read(blockListControllerProvider.notifier);
    print(
        '[BlockListView] build() called, blocks: ${state.blocks.length}, controller hashCode: ${controller.hashCode}');

    // Auto-scroll when new blocks are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.blocks.length > _lastBlockCount &&
          _scrollController.hasClients) {
        _scrollToBottom();
      }
      _lastBlockCount = state.blocks.length;
    });

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading blocks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.blocks.isEmpty) {
      return _EmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.blocks.length,
      itemBuilder: (context, index) {
        final block = state.blocks[index];
        return BlockWidget(
          key: ValueKey(block.id),
          block: block,
          onRerun: widget.onRerunCommand != null
              ? () => widget.onRerunCommand!(block.command)
              : null,
        );
      },
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

/// Empty state when no blocks exist yet.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terminal,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No commands yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commands and their output will appear here\nas collapsible blocks.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
