// @telos L1:function:lib/features/terminal/presentation/providers:block_provider

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/block_repository.dart';
import '../../domain/entities/block.dart';
import '../../domain/entities/block_status.dart';

part 'block_provider.g.dart';

/// Default session ID until session-tabs feature is implemented.
const kDefaultSessionId = 'default';

/// State for the block list.
class BlockListState {
  const BlockListState({
    this.blocks = const [],
    this.activeBlockId,
    this.isLoading = false,
    this.error,
  });

  /// List of blocks in the current session.
  final List<TerminalBlock> blocks;

  /// ID of the currently active (running) block.
  final String? activeBlockId;

  /// Whether blocks are being loaded from database.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Returns the active block if one exists.
  TerminalBlock? get activeBlock {
    if (activeBlockId == null) return null;
    return blocks.where((b) => b.id == activeBlockId).firstOrNull;
  }

  /// Returns true if there's an active running block.
  bool get hasActiveBlock => activeBlockId != null;

  BlockListState copyWith({
    List<TerminalBlock>? blocks,
    String? activeBlockId,
    bool clearActiveBlock = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BlockListState(
      blocks: blocks ?? this.blocks,
      activeBlockId:
          clearActiveBlock ? null : (activeBlockId ?? this.activeBlockId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controller for managing the list of terminal blocks.
///
/// Handles block creation, output streaming, status updates,
/// and persistence to database.
@Riverpod(keepAlive: true)
class BlockListController extends _$BlockListController {
  static const _uuid = Uuid();

  BlockRepository? _repository;
  String _sessionId = kDefaultSessionId;

  @override
  BlockListState build() {
    print('[BlockListController] build() called - initializing state');
    // Get repository (may be null if database not initialized)
    // Use ref.read instead of ref.watch to avoid rebuilding when repository changes
    try {
      _repository = ref.read(blockRepositoryProvider);
    } catch (_) {
      // Repository not available yet
    }

    return const BlockListState();
  }

  /// Sets the current session ID.
  void setSessionId(String sessionId) {
    _sessionId = sessionId;
  }

  /// Loads blocks from database for the current session.
  Future<void> loadBlocks() async {
    if (_repository == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final blocks = await _repository!.getBlocksForSession(_sessionId);
      state = state.copyWith(
        blocks: blocks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load blocks: $e',
      );
    }
  }

  /// Creates a new block for a command.
  ///
  /// New blocks start expanded. Existing blocks are auto-collapsed
  /// unless they were manually expanded by the user.
  ///
  /// Returns the created block's ID.
  String createBlock(String command) {
    print(
        '[BlockListController] createBlock called with: "$command" (this.hashCode: $hashCode)');
    print(
        '[BlockListController] Current state has ${state.blocks.length} blocks');

    final id = _uuid.v4();
    final now = DateTime.now();

    final block = TerminalBlock(
      id: id,
      sessionId: _sessionId,
      command: command,
      startedAt: now,
      status: BlockStatus.running,
      isCollapsed: false, // New blocks start expanded
    );

    // Auto-collapse existing blocks that weren't manually expanded
    final updatedBlocks = state.blocks.map((existingBlock) {
      if (!existingBlock.manuallyExpanded && !existingBlock.isCollapsed) {
        return existingBlock.copyWith(isCollapsed: true);
      }
      return existingBlock;
    }).toList();

    state = state.copyWith(
      blocks: [...updatedBlocks, block],
      activeBlockId: id,
    );

    print('[BlockListController] Block created with id: $id');
    print('[BlockListController] New state has ${state.blocks.length} blocks');

    return id;
  }

  /// Appends output to the active block.
  ///
  /// If [blockId] is provided, appends to that specific block.
  /// Otherwise appends to the currently active block.
  void appendOutput(String output, {String? blockId}) {
    final targetId = blockId ?? state.activeBlockId;
    if (targetId == null) return;

    state = state.copyWith(
      blocks: state.blocks.map((block) {
        if (block.id == targetId) {
          return block.copyWith(output: block.output + output);
        }
        return block;
      }).toList(),
    );
  }

  /// Completes a block with the given status and exit code.
  ///
  /// If [blockId] is provided, completes that specific block.
  /// Otherwise completes the currently active block.
  Future<void> completeBlock({
    BlockStatus status = BlockStatus.success,
    int? exitCode,
    String? blockId,
  }) async {
    final targetId = blockId ?? state.activeBlockId;
    if (targetId == null) return;

    final now = DateTime.now();

    state = state.copyWith(
      blocks: state.blocks.map((block) {
        if (block.id == targetId) {
          return block.copyWith(
            status: status,
            exitCode: exitCode,
            completedAt: now,
          );
        }
        return block;
      }).toList(),
      clearActiveBlock: targetId == state.activeBlockId,
    );

    // Persist to database
    await _persistBlock(targetId);
  }

  /// Toggles the collapsed state of a block.
  ///
  /// When a user manually expands a block, it's marked as `manuallyExpanded`
  /// so it won't be auto-collapsed when new commands are issued.
  /// When manually collapsed, the flag is cleared.
  void toggleCollapsed(String blockId) {
    state = state.copyWith(
      blocks: state.blocks.map((block) {
        if (block.id == blockId) {
          final willBeExpanded = block.isCollapsed;
          return block.copyWith(
            isCollapsed: !block.isCollapsed,
            // Mark as manually expanded if user is expanding it
            // Clear the flag if user is collapsing it
            manuallyExpanded: willBeExpanded,
          );
        }
        return block;
      }).toList(),
    );

    // Persist collapse state
    _persistBlock(blockId);
  }

  /// Collapses all blocks.
  void collapseAll() {
    state = state.copyWith(
      blocks: state.blocks.map((block) {
        return block.copyWith(isCollapsed: true);
      }).toList(),
    );
  }

  /// Expands all blocks.
  void expandAll() {
    state = state.copyWith(
      blocks: state.blocks.map((block) {
        return block.copyWith(isCollapsed: false);
      }).toList(),
    );
  }

  /// Deletes a block.
  Future<void> deleteBlock(String blockId) async {
    final block = state.blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;

    state = state.copyWith(
      blocks: state.blocks.where((b) => b.id != blockId).toList(),
      clearActiveBlock: blockId == state.activeBlockId,
    );

    // Delete from database
    await _repository?.deleteBlock(_sessionId, block.startedAt);
  }

  /// Clears all blocks for the current session.
  Future<void> clearBlocks() async {
    state = state.copyWith(
      blocks: [],
      clearActiveBlock: true,
    );

    await _repository?.deleteBlocksForSession(_sessionId);
  }

  /// Gets a block by ID.
  TerminalBlock? getBlock(String blockId) {
    return state.blocks.where((b) => b.id == blockId).firstOrNull;
  }

  /// Returns true if there's an active running block.
  bool get hasActiveBlock => state.hasActiveBlock;

  /// Returns the active block if one exists.
  TerminalBlock? get activeBlock => state.activeBlock;

  /// Persists a block to the database.
  Future<void> _persistBlock(String blockId) async {
    if (_repository == null) return;

    final block = state.blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;

    try {
      // Try to update first, if that fails (not found), insert
      final updated = await _repository!.updateBlock(block);
      if (!updated) {
        await _repository!.saveBlock(block);
      }
    } catch (e) {
      // Log error but don't crash - persistence is best-effort
      // In production, you'd use a proper logging framework
    }
  }
}
