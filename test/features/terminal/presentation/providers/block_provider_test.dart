// @telos-test L1:function:lib/features/terminal/presentation/providers:block_provider

import 'package:bento/features/terminal/domain/entities/block.dart';
import 'package:bento/features/terminal/domain/entities/block_status.dart';
import 'package:bento/features/terminal/presentation/providers/block_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BlockListController', () {
    late ProviderContainer container;
    late BlockListController controller;

    setUp(() {
      container = ProviderContainer();
      controller = container.read(blockListControllerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('createBlock', () {
      // @telos-scenario L1:...:block_provider:create-block-adds-to-state
      test('adds new block to state', () {
        // GIVEN: Empty state
        expect(controller.state.blocks, isEmpty);

        // WHEN: Creating a block
        final blockId = controller.createBlock('ls -la');

        // THEN: Block is added to state
        expect(controller.state.blocks, hasLength(1));
        expect(controller.state.blocks.first.id, blockId);
        expect(controller.state.blocks.first.command, 'ls -la');
        expect(controller.state.blocks.first.status, BlockStatus.running);
        expect(controller.state.blocks.first.isCollapsed,
            false); // New blocks start expanded
      });

      // @telos-scenario L1:...:block_provider:create-block-sets-active
      test('sets new block as active', () {
        // WHEN: Creating a block
        final blockId = controller.createBlock('pwd');

        // THEN: Block is set as active
        expect(controller.state.activeBlockId, blockId);
        expect(controller.hasActiveBlock, true);
        expect(controller.activeBlock?.command, 'pwd');
      });

      // @telos-scenario L1:...:block_provider:create-block-auto-collapses-old
      test('new blocks are expanded, older blocks are auto-collapsed', () {
        // GIVEN: An existing block (starts expanded)
        controller.createBlock('first command');
        expect(controller.state.blocks.first.isCollapsed, false);

        // WHEN: Creating a second block
        controller.createBlock('second command');

        // THEN: First block is auto-collapsed, second is expanded
        expect(controller.state.blocks[0].isCollapsed, true);
        expect(controller.state.blocks[1].isCollapsed, false);
      });

      // @telos-scenario L1:...:block_provider:create-block-keeps-manually-expanded
      test('keeps manually expanded blocks expanded when new block created',
          () {
        // GIVEN: A block that was manually expanded
        controller.createBlock('first command');
        // Collapse it first, then expand (sets manuallyExpanded)
        controller.toggleCollapsed(controller.state.blocks.first.id);
        controller.toggleCollapsed(controller.state.blocks.first.id);
        expect(controller.state.blocks.first.manuallyExpanded, true);

        // WHEN: Creating a second block
        controller.createBlock('second command');

        // THEN: First block stays expanded (manuallyExpanded), second is also expanded
        expect(controller.state.blocks[0].isCollapsed, false);
        expect(controller.state.blocks[1].isCollapsed, false);
      });

      // @telos-scenario L1:...:block_provider:create-block-records-timestamp
      test('records timestamp when block is created', () {
        // GIVEN: Current time
        final before = DateTime.now();

        // WHEN: Creating a block
        controller.createBlock('date');

        // THEN: Timestamp is recorded
        final after = DateTime.now();
        final block = controller.state.blocks.first;
        expect(
            block.startedAt
                .isAfter(before.subtract(const Duration(seconds: 1))),
            true);
        expect(block.startedAt.isBefore(after.add(const Duration(seconds: 1))),
            true);
      });

      // @telos-scenario L1:...:block_provider:multiple-rapid-creates
      test('handles multiple rapid createBlock calls', () {
        // WHEN: Creating multiple blocks rapidly
        final id1 = controller.createBlock('cmd1');
        final id2 = controller.createBlock('cmd2');
        final id3 = controller.createBlock('cmd3');

        // THEN: All blocks are created with unique IDs
        expect(controller.state.blocks, hasLength(3));
        expect({id1, id2, id3}.length, 3); // All unique
        expect(controller.state.blocks.map((b) => b.command).toList(),
            ['cmd1', 'cmd2', 'cmd3']);
      });

      // @telos-scenario L1:...:block_provider:create-block-unique-ids
      test('generates unique IDs for each block', () {
        // WHEN: Creating many blocks
        final ids = <String>[];
        for (var i = 0; i < 100; i++) {
          ids.add(controller.createBlock('cmd$i'));
        }

        // THEN: All IDs are unique
        expect(ids.toSet().length, 100);
      });
    });

    group('appendOutput', () {
      // @telos-scenario L1:...:block_provider:append-output-to-active
      test('appends output to active block', () {
        // GIVEN: An active block
        controller.createBlock('ls');

        // WHEN: Appending output
        controller.appendOutput('file1.txt\n');
        controller.appendOutput('file2.txt\n');

        // THEN: Output is appended
        expect(controller.activeBlock?.output, 'file1.txt\nfile2.txt\n');
      });

      // @telos-scenario L1:...:block_provider:append-output-no-active
      test('does nothing when no active block', () {
        // GIVEN: No active block
        expect(controller.hasActiveBlock, false);

        // WHEN: Appending output
        controller.appendOutput('orphan output');

        // THEN: Nothing happens (no crash)
        expect(controller.state.blocks, isEmpty);
      });

      // @telos-scenario L1:...:block_provider:append-output-specific-block
      test('appends to specific block by ID', () {
        // GIVEN: Multiple blocks
        final id1 = controller.createBlock('cmd1');
        controller.createBlock('cmd2');

        // WHEN: Appending to specific block (not active)
        controller.appendOutput('output for cmd1', blockId: id1);

        // THEN: Output goes to specified block
        expect(controller.getBlock(id1)?.output, 'output for cmd1');
        expect(controller.activeBlock?.output, ''); // Active block unchanged
      });
    });

    group('completeBlock', () {
      // @telos-scenario L1:...:block_provider:complete-block-success
      test('completes block with success status', () async {
        // GIVEN: An active running block
        final blockId = controller.createBlock('echo hello');
        expect(controller.activeBlock?.status, BlockStatus.running);

        // WHEN: Completing the block
        await controller.completeBlock(
            status: BlockStatus.success, exitCode: 0);

        // THEN: Block is completed
        final block = controller.getBlock(blockId);
        expect(block?.status, BlockStatus.success);
        expect(block?.exitCode, 0);
        expect(block?.completedAt, isNotNull);
        expect(controller.hasActiveBlock, false);
      });

      // @telos-scenario L1:...:block_provider:complete-block-failed
      test('completes block with failed status', () async {
        // GIVEN: An active running block
        controller.createBlock('invalid_command');

        // WHEN: Completing with failure
        await controller.completeBlock(
            status: BlockStatus.failed, exitCode: 127);

        // THEN: Block shows failure
        expect(controller.state.blocks.first.status, BlockStatus.failed);
        expect(controller.state.blocks.first.exitCode, 127);
      });

      // @telos-scenario L1:...:block_provider:complete-block-cancelled
      test('completes block with cancelled status', () async {
        // GIVEN: An active running block
        controller.createBlock('long_running_command');

        // WHEN: Cancelling
        await controller.completeBlock(status: BlockStatus.cancelled);

        // THEN: Block shows cancelled
        expect(controller.state.blocks.first.status, BlockStatus.cancelled);
      });

      // @telos-scenario L1:...:block_provider:complete-clears-active
      test('clears active block ID after completion', () async {
        // GIVEN: An active block
        controller.createBlock('cmd');
        expect(controller.hasActiveBlock, true);

        // WHEN: Completing
        await controller.completeBlock();

        // THEN: No active block
        expect(controller.hasActiveBlock, false);
        expect(controller.state.activeBlockId, isNull);
      });
    });

    group('toggleCollapsed', () {
      // @telos-scenario L1:...:block_provider:toggle-collapse
      test('toggles collapsed state', () {
        // GIVEN: An expanded block (new blocks start expanded)
        final blockId = controller.createBlock('cmd');
        expect(controller.state.blocks.first.isCollapsed, false);

        // WHEN: Toggling (collapsing)
        controller.toggleCollapsed(blockId);

        // THEN: Block is collapsed
        expect(controller.state.blocks.first.isCollapsed, true);

        // WHEN: Toggling again
        controller.toggleCollapsed(blockId);

        // THEN: Block is expanded
        expect(controller.state.blocks.first.isCollapsed, false);
      });

      // @telos-scenario L1:...:block_provider:toggle-sets-manually-expanded
      test('sets manuallyExpanded flag when expanding from collapsed', () {
        // GIVEN: A collapsed block (collapse it first)
        final blockId = controller.createBlock('cmd');
        controller.toggleCollapsed(blockId); // Collapse it
        expect(controller.state.blocks.first.isCollapsed, true);
        expect(controller.state.blocks.first.manuallyExpanded, false);

        // WHEN: Expanding it
        controller.toggleCollapsed(blockId);

        // THEN: manuallyExpanded is set
        expect(controller.state.blocks.first.isCollapsed, false);
        expect(controller.state.blocks.first.manuallyExpanded, true);
      });

      // @telos-scenario L1:...:block_provider:toggle-clears-manually-expanded
      test('clears manuallyExpanded flag when collapsing', () {
        // GIVEN: A manually expanded block
        final blockId = controller.createBlock('cmd');
        controller.toggleCollapsed(blockId); // Collapse
        controller.toggleCollapsed(blockId); // Expand (sets manuallyExpanded)
        expect(controller.state.blocks.first.manuallyExpanded, true);

        // WHEN: Collapsing it
        controller.toggleCollapsed(blockId);

        // THEN: manuallyExpanded is cleared
        expect(controller.state.blocks.first.isCollapsed, true);
        expect(controller.state.blocks.first.manuallyExpanded, false);
      });
    });

    group('clearBlocks', () {
      // @telos-scenario L1:...:block_provider:clear-blocks
      test('removes all blocks', () async {
        // GIVEN: Multiple blocks
        controller.createBlock('cmd1');
        controller.createBlock('cmd2');
        controller.createBlock('cmd3');
        expect(controller.state.blocks, hasLength(3));

        // WHEN: Clearing
        await controller.clearBlocks();

        // THEN: All blocks removed
        expect(controller.state.blocks, isEmpty);
        expect(controller.hasActiveBlock, false);
      });
    });

    group('collapseAll / expandAll', () {
      // @telos-scenario L1:...:block_provider:collapse-all
      test('collapses all blocks', () {
        // GIVEN: Multiple blocks (new blocks start expanded, older auto-collapse)
        controller.createBlock('cmd1');
        controller.createBlock('cmd2');
        // cmd1 is collapsed (auto), cmd2 is expanded (newest)
        expect(controller.state.blocks[0].isCollapsed, true);
        expect(controller.state.blocks[1].isCollapsed, false);

        // WHEN: Collapsing all
        controller.collapseAll();

        // THEN: All blocks collapsed
        expect(controller.state.blocks.every((b) => b.isCollapsed), true);
      });

      // @telos-scenario L1:...:block_provider:expand-all
      test('expands all blocks', () {
        // GIVEN: Multiple blocks, collapse all first
        controller.createBlock('cmd1');
        controller.createBlock('cmd2');
        controller.collapseAll();
        expect(controller.state.blocks.every((b) => b.isCollapsed), true);

        // WHEN: Expanding all
        controller.expandAll();

        // THEN: All blocks expanded
        expect(controller.state.blocks.every((b) => !b.isCollapsed), true);
      });
    });

    group('deleteBlock', () {
      // @telos-scenario L1:...:block_provider:delete-block
      test('removes specific block', () async {
        // GIVEN: Multiple blocks
        final id1 = controller.createBlock('cmd1');
        controller.createBlock('cmd2');
        expect(controller.state.blocks, hasLength(2));

        // WHEN: Deleting first block
        await controller.deleteBlock(id1);

        // THEN: Only second block remains
        expect(controller.state.blocks, hasLength(1));
        expect(controller.state.blocks.first.command, 'cmd2');
      });

      // @telos-scenario L1:...:block_provider:delete-active-block
      test('clears active when deleting active block', () async {
        // GIVEN: An active block
        final blockId = controller.createBlock('cmd');
        expect(controller.state.activeBlockId, blockId);

        // WHEN: Deleting it
        await controller.deleteBlock(blockId);

        // THEN: Active is cleared
        expect(controller.hasActiveBlock, false);
      });
    });

    group('getBlock', () {
      // @telos-scenario L1:...:block_provider:get-block
      test('returns block by ID', () {
        // GIVEN: A block
        final blockId = controller.createBlock('test');

        // WHEN: Getting by ID
        final block = controller.getBlock(blockId);

        // THEN: Correct block returned
        expect(block?.id, blockId);
        expect(block?.command, 'test');
      });

      // @telos-scenario L1:...:block_provider:get-block-not-found
      test('returns null for unknown ID', () {
        // GIVEN: A block
        controller.createBlock('test');

        // WHEN: Getting unknown ID
        final block = controller.getBlock('unknown-id');

        // THEN: Null returned
        expect(block, isNull);
      });
    });

    group('state notifications', () {
      // @telos-scenario L1:...:block_provider:state-updates-trigger-rebuild
      test('state updates trigger UI rebuild', () {
        // Track state changes
        var stateChangeCount = 0;
        container.listen(
          blockListControllerProvider,
          (previous, next) {
            stateChangeCount++;
          },
          fireImmediately: false,
        );

        // WHEN: Creating blocks
        controller.createBlock('cmd1');
        controller.createBlock('cmd2');

        // THEN: State changed for each operation
        expect(stateChangeCount, 2);
      });
    });
  });

  group('BlockListState', () {
    // @telos-scenario L1:...:block_provider:state-has-active-block
    test('hasActiveBlock returns correct value', () {
      const stateWithActive = BlockListState(activeBlockId: 'some-id');
      const stateWithoutActive = BlockListState();

      expect(stateWithActive.hasActiveBlock, true);
      expect(stateWithoutActive.hasActiveBlock, false);
    });

    // @telos-scenario L1:...:block_provider:state-active-block
    test('activeBlock returns correct block', () {
      final block = TerminalBlock(
        id: 'block-1',
        sessionId: 'session',
        command: 'test',
        startedAt: DateTime.now(),
      );

      final state = BlockListState(
        blocks: [block],
        activeBlockId: 'block-1',
      );

      expect(state.activeBlock, block);
    });

    // @telos-scenario L1:...:block_provider:state-active-block-not-found
    test('activeBlock returns null when ID not in blocks', () {
      final state = BlockListState(
        blocks: [],
        activeBlockId: 'missing-id',
      );

      expect(state.activeBlock, isNull);
    });

    // @telos-scenario L1:...:block_provider:state-copy-with
    test('copyWith preserves unmodified fields', () {
      final original = BlockListState(
        blocks: [
          TerminalBlock(
            id: 'b1',
            sessionId: 's1',
            command: 'cmd',
            startedAt: DateTime.now(),
          ),
        ],
        activeBlockId: 'b1',
        isLoading: true,
        error: 'some error',
      );

      final modified = original.copyWith(isLoading: false);

      expect(modified.blocks, original.blocks);
      expect(modified.activeBlockId, original.activeBlockId);
      expect(modified.isLoading, false);
      expect(modified.error, original.error);
    });

    // @telos-scenario L1:...:block_provider:state-copy-with-clear-active
    test('copyWith clearActiveBlock works', () {
      const original = BlockListState(activeBlockId: 'some-id');
      final modified = original.copyWith(clearActiveBlock: true);

      expect(modified.activeBlockId, isNull);
    });

    // @telos-scenario L1:...:block_provider:state-copy-with-clear-error
    test('copyWith clearError works', () {
      const original = BlockListState(error: 'some error');
      final modified = original.copyWith(clearError: true);

      expect(modified.error, isNull);
    });
  });
}
