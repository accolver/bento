// @telos L1:function:lib/features/terminal/presentation/widgets:block_list_view

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/block_provider.dart';
import '../providers/block_search_provider.dart';
import 'block_widget.dart';

/// Displays a virtualized list of terminal blocks with optional search.
///
/// Features:
/// - Efficient rendering with ListView.builder
/// - Auto-scrolls to new blocks at bottom
/// - Search bar to filter blocks by command or output text
/// - Empty state when no blocks
class BlockListView extends ConsumerStatefulWidget {
  const BlockListView({
    required this.sessionId,
    this.onRerunCommand,
    super.key,
  });

  /// The session ID to display blocks for.
  final String sessionId;

  /// Callback when user wants to re-run a command.
  final void Function(String command)? onRerunCommand;

  @override
  ConsumerState<BlockListView> createState() => _BlockListViewState();
}

class _BlockListViewState extends ConsumerState<BlockListView> {
  final ScrollController _scrollController = ScrollController();
  int _lastBlockCount = 0;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blockListControllerProvider(widget.sessionId));
    final filteredBlocks = ref.watch(filteredBlocksProvider(widget.sessionId));
    final searchQuery =
        ref.watch(blockSearchControllerProvider(widget.sessionId));

    // Auto-scroll when new blocks are added (only when not searching)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searchQuery.isEmpty &&
          state.blocks.length > _lastBlockCount &&
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

    return Column(
      children: [
        // Search toggle + search bar
        _SearchBar(
          sessionId: widget.sessionId,
          showSearch: _showSearch,
          searchController: _searchController,
          onToggleSearch: _toggleSearch,
          resultCount: searchQuery.isNotEmpty ? filteredBlocks.length : null,
          totalCount: state.blocks.length,
        ),
        // Block list
        Expanded(
          child: filteredBlocks.isEmpty && searchQuery.isNotEmpty
              ? _NoSearchResults(query: searchQuery)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredBlocks.length,
                  itemBuilder: (context, index) {
                    final block = filteredBlocks[index];
                    return BlockWidget(
                      key: ValueKey(block.id),
                      block: block,
                      onRerun: widget.onRerunCommand,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref
            .read(blockSearchControllerProvider(widget.sessionId).notifier)
            .clear();
      }
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

/// Search bar widget for filtering blocks.
class _SearchBar extends ConsumerWidget {
  const _SearchBar({
    required this.sessionId,
    required this.showSearch,
    required this.searchController,
    required this.onToggleSearch,
    required this.totalCount,
    this.resultCount,
  });

  final String sessionId;
  final bool showSearch;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final int? resultCount;
  final int totalCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle bar - always visible
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Search toggle icon
                IconButton(
                  icon: Icon(
                    showSearch ? Icons.search_off : Icons.search,
                    size: 18,
                  ),
                  onPressed: onToggleSearch,
                  tooltip: showSearch ? 'Hide search' : 'Search blocks',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                const Spacer(),
                // Result count indicator
                if (resultCount != null)
                  Text(
                    '$resultCount of $totalCount blocks',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    '$totalCount blocks',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Search input field - shown when toggled
          if (showSearch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'JetBrainsMonoNF',
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Filter by command or output...',
                  hintStyle: TextStyle(
                    fontFamily: 'JetBrainsMonoNF',
                    fontSize: 13,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            searchController.clear();
                            ref
                                .read(
                                  blockSearchControllerProvider(sessionId)
                                      .notifier,
                                )
                                .clear();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  ref
                      .read(blockSearchControllerProvider(sessionId).notifier)
                      .setQuery(value);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown when search returns no results.
class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No blocks match "$query"',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
