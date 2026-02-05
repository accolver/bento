// @telos-test L1:function:lib/features/terminal/domain/entities:terminal_block

import 'dart:convert';

import 'package:bento/features/terminal/domain/entities/block.dart';
import 'package:bento/features/terminal/domain/entities/block_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerminalBlock', () {
    final now = DateTime.now();

    TerminalBlock createTestBlock({
      String id = 'test-id',
      String sessionId = 'session-1',
      String command = 'ls -la',
      String output = 'file1.txt\nfile2.txt',
      BlockStatus status = BlockStatus.success,
      int? exitCode = 0,
      DateTime? startedAt,
      DateTime? completedAt,
      bool isCollapsed = false,
      bool isTruncated = false,
    }) {
      return TerminalBlock(
        id: id,
        sessionId: sessionId,
        command: command,
        output: output,
        status: status,
        exitCode: exitCode,
        startedAt: startedAt ?? now,
        completedAt: completedAt,
        isCollapsed: isCollapsed,
        isTruncated: isTruncated,
      );
    }

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_block:create-new-block
    test('can be created with required parameters', () {
      final block = TerminalBlock(
        id: 'test-123',
        sessionId: 'session-1',
        command: 'echo hello',
        startedAt: now,
      );

      expect(block.id, 'test-123');
      expect(block.sessionId, 'session-1');
      expect(block.command, 'echo hello');
      expect(block.output, ''); // default
      expect(block.status, BlockStatus.running); // default
      expect(block.exitCode, isNull);
      expect(block.startedAt, now);
      expect(block.completedAt, isNull);
      expect(block.isCollapsed, false); // default
      expect(block.isTruncated, false); // default
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_block:block-immutability
    test('copyWith creates new instance without modifying original', () {
      final original = createTestBlock();
      final modified = original.copyWith(output: 'new output');

      expect(modified.output, 'new output');
      expect(original.output, 'file1.txt\nfile2.txt');
      expect(identical(original, modified), false);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_block:serialize-to-json
    test('serializes to JSON correctly', () {
      final block = createTestBlock(
        startedAt: DateTime.utc(2026, 2, 4, 12, 0, 0),
        completedAt: DateTime.utc(2026, 2, 4, 12, 0, 5),
      );

      final json = block.toJson();

      expect(json['id'], 'test-id');
      expect(json['sessionId'], 'session-1');
      expect(json['command'], 'ls -la');
      expect(json['output'], 'file1.txt\nfile2.txt');
      expect(json['status'], 'success');
      expect(json['exitCode'], 0);
      expect(json['isCollapsed'], false);
      expect(json['isTruncated'], false);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_block:deserialize-from-json
    test('deserializes from JSON correctly', () {
      final json = {
        'id': 'block-456',
        'sessionId': 'session-2',
        'command': 'pwd',
        'output': '/home/user',
        'status': 'success',
        'exitCode': 0,
        'startedAt': '2026-02-04T12:00:00.000Z',
        'completedAt': '2026-02-04T12:00:01.000Z',
        'isCollapsed': true,
        'isTruncated': false,
      };

      final block = TerminalBlock.fromJson(json);

      expect(block.id, 'block-456');
      expect(block.sessionId, 'session-2');
      expect(block.command, 'pwd');
      expect(block.output, '/home/user');
      expect(block.status, BlockStatus.success);
      expect(block.exitCode, 0);
      expect(block.isCollapsed, true);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_block:equal-blocks
    test('equal blocks have same hashCode', () {
      final block1 = createTestBlock();
      final block2 = createTestBlock();

      expect(block1, equals(block2));
      expect(block1.hashCode, block2.hashCode);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/entities:terminal_block:unequal-blocks
    test('blocks with different properties are not equal', () {
      final block1 = createTestBlock(command: 'ls');
      final block2 = createTestBlock(command: 'pwd');

      expect(block1, isNot(equals(block2)));
    });

    group('computed properties', () {
      test('executionDuration returns null when not completed', () {
        final block = createTestBlock(
          status: BlockStatus.running,
          completedAt: null,
        );

        expect(block.executionDuration, isNull);
      });

      test('executionDuration returns correct duration when completed', () {
        final started = DateTime.utc(2026, 2, 4, 12, 0, 0);
        final completed = DateTime.utc(2026, 2, 4, 12, 0, 5);

        final block = createTestBlock(
          startedAt: started,
          completedAt: completed,
        );

        expect(block.executionDuration, const Duration(seconds: 5));
      });

      test('outputLineCount counts lines correctly', () {
        final block = createTestBlock(output: 'line1\nline2\nline3');
        expect(block.outputLineCount, 3);
      });

      test('outputLineCount returns 1 for single line', () {
        final block = createTestBlock(output: 'single line');
        expect(block.outputLineCount, 1);
      });

      test('isRunning returns true for running status', () {
        final block = createTestBlock(status: BlockStatus.running);
        expect(block.isRunning, true);
      });

      test('isRunning returns false for completed status', () {
        final block = createTestBlock(status: BlockStatus.success);
        expect(block.isRunning, false);
      });

      test('isCompleted returns false for running status', () {
        final block = createTestBlock(status: BlockStatus.running);
        expect(block.isCompleted, false);
      });

      test('isCompleted returns true for success status', () {
        final block = createTestBlock(status: BlockStatus.success);
        expect(block.isCompleted, true);
      });

      test('isCompleted returns true for failed status', () {
        final block = createTestBlock(status: BlockStatus.failed);
        expect(block.isCompleted, true);
      });

      test('isCompleted returns true for cancelled status', () {
        final block = createTestBlock(status: BlockStatus.cancelled);
        expect(block.isCompleted, true);
      });
    });
  });

  group('BlockStatus', () {
    // @telos-scenario L1:function:lib/features/terminal/domain/entities:block_status:status-values
    test('has all expected values', () {
      expect(BlockStatus.values, hasLength(4));
      expect(BlockStatus.values, contains(BlockStatus.running));
      expect(BlockStatus.values, contains(BlockStatus.success));
      expect(BlockStatus.values, contains(BlockStatus.failed));
      expect(BlockStatus.values, contains(BlockStatus.cancelled));
    });

    test('isTerminal returns correct values', () {
      expect(BlockStatus.running.isTerminal, false);
      expect(BlockStatus.success.isTerminal, true);
      expect(BlockStatus.failed.isTerminal, true);
      expect(BlockStatus.cancelled.isTerminal, true);
    });

    test('isError returns correct values', () {
      expect(BlockStatus.running.isError, false);
      expect(BlockStatus.success.isError, false);
      expect(BlockStatus.failed.isError, true);
      expect(BlockStatus.cancelled.isError, true);
    });

    test('label returns human-readable strings', () {
      expect(BlockStatus.running.label, 'Running');
      expect(BlockStatus.success.label, 'Success');
      expect(BlockStatus.failed.label, 'Failed');
      expect(BlockStatus.cancelled.label, 'Cancelled');
    });
  });
}
