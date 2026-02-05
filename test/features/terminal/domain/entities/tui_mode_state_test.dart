// @telos-test L1:function:lib/features/terminal/domain/entities:tui_mode_state

import 'package:bento/features/terminal/domain/entities/tui_mode_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TuiModeState', () {
    // @telos-scenario L1:...:tui_mode_state:inactive-state
    test('inactive constructor creates inactive state', () {
      const state = TuiModeState.inactive();

      expect(state.isActive, isFalse);
      expect(state.activatedAt, isNull);
      expect(state.triggeringCommand, isNull);
      expect(state.tuiBlockId, isNull);
    });

    // @telos-scenario L1:...:tui_mode_state:active-state
    test('active factory creates active state with all fields', () {
      final now = DateTime.now();
      final state = TuiModeState.active(
        activatedAt: now,
        triggeringCommand: 'vim file.txt',
        tuiBlockId: 'block-123',
      );

      expect(state.isActive, isTrue);
      expect(state.activatedAt, equals(now));
      expect(state.triggeringCommand, equals('vim file.txt'));
      expect(state.tuiBlockId, equals('block-123'));
    });

    // @telos-scenario L1:...:tui_mode_state:active-state-optional-fields
    test('active factory works with only required fields', () {
      final now = DateTime.now();
      final state = TuiModeState.active(activatedAt: now);

      expect(state.isActive, isTrue);
      expect(state.activatedAt, equals(now));
      expect(state.triggeringCommand, isNull);
      expect(state.tuiBlockId, isNull);
    });

    // @telos-scenario L1:...:tui_mode_state:elapsed-duration-active
    test('elapsedDuration returns duration when active', () {
      final past = DateTime.now().subtract(const Duration(seconds: 5));
      final state = TuiModeState.active(activatedAt: past);

      final elapsed = state.elapsedDuration;

      expect(elapsed, isNotNull);
      expect(elapsed!.inSeconds, greaterThanOrEqualTo(5));
    });

    // @telos-scenario L1:...:tui_mode_state:elapsed-duration-inactive
    test('elapsedDuration returns null when inactive', () {
      const state = TuiModeState.inactive();

      expect(state.elapsedDuration, isNull);
    });

    // @telos-scenario L1:...:tui_mode_state:copy-with
    test('copyWith creates modified copy', () {
      final original = TuiModeState.active(
        activatedAt: DateTime.now(),
        triggeringCommand: 'vim',
      );

      final modified = original.copyWith(
        triggeringCommand: 'htop',
        tuiBlockId: 'new-block',
      );

      expect(modified.isActive, isTrue);
      expect(modified.activatedAt, equals(original.activatedAt));
      expect(modified.triggeringCommand, equals('htop'));
      expect(modified.tuiBlockId, equals('new-block'));
    });

    // @telos-scenario L1:...:tui_mode_state:deactivate
    test('deactivate returns inactive state', () {
      final active = TuiModeState.active(
        activatedAt: DateTime.now(),
        triggeringCommand: 'vim',
      );

      final deactivated = active.deactivate();

      expect(deactivated.isActive, isFalse);
      expect(deactivated.activatedAt, isNull);
      expect(deactivated.triggeringCommand, isNull);
    });

    // @telos-scenario L1:...:tui_mode_state:equality
    test('equality based on all fields', () {
      final now = DateTime.now();
      final state1 = TuiModeState.active(
        activatedAt: now,
        triggeringCommand: 'vim',
      );
      final state2 = TuiModeState.active(
        activatedAt: now,
        triggeringCommand: 'vim',
      );
      final state3 = TuiModeState.active(
        activatedAt: now,
        triggeringCommand: 'htop',
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    // @telos-scenario L1:...:tui_mode_state:to-string
    test('toString provides useful output', () {
      const inactive = TuiModeState.inactive();
      final active = TuiModeState.active(
        activatedAt: DateTime.now(),
        triggeringCommand: 'vim',
      );

      expect(inactive.toString(), contains('inactive'));
      expect(active.toString(), contains('active'));
      expect(active.toString(), contains('vim'));
    });
  });
}
