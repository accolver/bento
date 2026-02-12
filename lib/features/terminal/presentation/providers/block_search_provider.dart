// @telos L1:function:lib/features/terminal/presentation/providers:block_search

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/block.dart';
import 'block_provider.dart';

part 'block_search_provider.g.dart';

/// Controls block search state for a session.
@riverpod
class BlockSearchController extends _$BlockSearchController {
  @override
  String build(String sessionId) => '';

  /// Updates the search query.
  void setQuery(String query) {
    state = query;
  }

  /// Clears the search query.
  void clear() {
    state = '';
  }
}

/// Provides filtered blocks based on search query.
@riverpod
List<TerminalBlock> filteredBlocks(FilteredBlocksRef ref, String sessionId) {
  final query = ref.watch(blockSearchControllerProvider(sessionId));
  final blockState = ref.watch(blockListControllerProvider(sessionId));

  if (query.isEmpty) {
    return blockState.blocks;
  }

  final lowerQuery = query.toLowerCase();
  return blockState.blocks.where((block) {
    return block.command.toLowerCase().contains(lowerQuery) ||
        block.output.toLowerCase().contains(lowerQuery);
  }).toList();
}
