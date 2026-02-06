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

/// Maximum output size in memory before truncation (100KB).
const kMaxOutputSizeBytes = 100 * 1024;

/// Truncation indicator appended when output is truncated.
const kTruncationIndicator =
    '\n\n... [Output truncated. Use "Load Full Output" to view all.] ...';

/// Controller for managing the list of terminal blocks.
///
/// Handles block creation, output streaming, status updates,
/// and persistence to database.
@Riverpod(keepAlive: true)
class BlockListController extends _$BlockListController {
  static const _uuid = Uuid();

  BlockRepository? _repository;
  String _sessionId = kDefaultSessionId;

  /// Stores the full output for blocks that have been truncated in memory.
  /// Key: blockId, Value: full output string
  final Map<String, String> _fullOutputCache = {};

  @override
  BlockListState build() {
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

    return id;
  }

  /// Appends output to the active block.
  ///
  /// If [blockId] is provided, appends to that specific block.
  /// Otherwise appends to the currently active block.
  ///
  /// Output is truncated in memory when it exceeds [kMaxOutputSizeBytes].
  /// The full output is stored in [_fullOutputCache] for later retrieval.
  void appendOutput(String output, {String? blockId}) {
    final targetId = blockId ?? state.activeBlockId;
    if (targetId == null) return;

    state = state.copyWith(
      blocks: state.blocks.map((block) {
        if (block.id == targetId) {
          final newOutput = block.output + output;
          final outputBytes = newOutput.length; // UTF-8 approximation

          // Check if truncation is needed
          if (outputBytes > kMaxOutputSizeBytes && !block.isTruncated) {
            // Store full output in cache for later retrieval
            _fullOutputCache[targetId] = newOutput;

            // Truncate and mark as truncated
            final truncatedOutput =
                newOutput.substring(0, kMaxOutputSizeBytes) +
                    kTruncationIndicator;
            return block.copyWith(
              output: truncatedOutput,
              isTruncated: true,
            );
          } else if (block.isTruncated) {
            // Already truncated - update the cache but not the displayed output
            final currentFull = _fullOutputCache[targetId] ?? '';
            _fullOutputCache[targetId] = currentFull + output;
            return block; // Keep displayed output as-is
          }

          return block.copyWith(output: newOutput);
        }
        return block;
      }).toList(),
    );
  }

  /// Loads the full output for a truncated block.
  ///
  /// Returns the full output if available, or null if not truncated
  /// or not found in cache.
  String? getFullOutput(String blockId) {
    return _fullOutputCache[blockId];
  }

  /// Expands a truncated block to show full output.
  ///
  /// This replaces the truncated output with the full output from cache.
  /// Note: This can cause memory pressure for very large outputs.
  void loadFullOutput(String blockId) {
    final fullOutput = _fullOutputCache[blockId];
    if (fullOutput == null) return;

    state = state.copyWith(
      blocks: state.blocks.map((block) {
        if (block.id == blockId && block.isTruncated) {
          return block.copyWith(
            output: fullOutput,
            isTruncated:
                false, // Mark as not truncated since we're showing full
          );
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

  /// Creates a TUI session block when entering TUI mode.
  ///
  /// TUI session blocks are different from regular blocks:
  /// - They have `isTuiSession = true`
  /// - They don't capture output (TUI apps use alternate screen buffer)
  /// - They just record the command, duration, and exit status
  ///
  /// Returns the created block's ID.
  String createTuiSessionBlock(String? triggeringCommand) {
    final id = _uuid.v4();
    final now = DateTime.now();

    final block = TerminalBlock(
      id: id,
      sessionId: _sessionId,
      command: triggeringCommand ?? 'TUI Session',
      startedAt: now,
      status: BlockStatus.running,
      isCollapsed: false, // TUI session blocks start expanded
      isTuiSession: true,
      output: '', // TUI sessions don't capture output
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

    return id;
  }

  /// Completes a TUI session block when exiting TUI mode.
  ///
  /// Sets the completion time and status. For TUI sessions,
  /// we typically don't have exit codes, so we default to success.
  Future<void> completeTuiSessionBlock({
    BlockStatus status = BlockStatus.success,
    String? blockId,
  }) async {
    final targetId = blockId ?? state.activeBlockId;
    if (targetId == null) return;

    // Verify this is actually a TUI session block
    final block = getBlock(targetId);
    if (block == null || !block.isTuiSession) return;

    await completeBlock(status: status, blockId: targetId);
  }

  /// Marks any active TUI session as cancelled.
  ///
  /// Call this on disconnect or app termination to properly close
  /// any interrupted TUI sessions.
  Future<void> cancelActiveTuiSession() async {
    final active = state.activeBlock;
    if (active == null || !active.isTuiSession) return;

    await completeBlock(
      status: BlockStatus.cancelled,
      blockId: active.id,
    );
  }

  /// Returns the active TUI session block if one exists.
  TerminalBlock? get activeTuiSession {
    final active = state.activeBlock;
    if (active != null && active.isTuiSession) {
      return active;
    }
    return null;
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
