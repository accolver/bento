// @telos-test L1:function:lib/features/terminal/data/services:tui_mode_detector

import 'dart:async';
import 'dart:typed_data';

import 'package:bento/features/terminal/data/services/tui_mode_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TuiModeDetector detector;
  late List<TuiModeEvent> events;
  late StreamSubscription<TuiModeEvent> subscription;

  setUp(() {
    // Use very short debounce for testing
    detector =
        TuiModeDetector(debounceDuration: const Duration(milliseconds: 10));
    events = [];
    subscription = detector.events.listen(events.add);
  });

  tearDown(() {
    subscription.cancel();
    detector.dispose();
  });

  /// Helper to create smcup sequence as bytes
  Uint8List smcup() => Uint8List.fromList(TuiModeDetector.smcupSequence);

  /// Helper to create rmcup sequence as bytes
  Uint8List rmcup() => Uint8List.fromList(TuiModeDetector.rmcupSequence);

  group('TuiModeDetector', () {
    // @telos-scenario L1:...:tui_mode_detector:initial-state
    test('initial state is inactive', () {
      expect(detector.isActive, isFalse);
    });

    // @telos-scenario L1:...:tui_mode_detector:detect-smcup
    test('detects smcup and activates TUI mode after debounce', () async {
      detector.processOutput(smcup());

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 20));

      expect(detector.isActive, isTrue);
      expect(events, hasLength(1));
      expect(events.first, isA<TuiModeActivated>());
    });

    // @telos-scenario L1:...:tui_mode_detector:detect-rmcup
    test('detects rmcup and deactivates TUI mode', () async {
      // First activate
      detector.processOutput(smcup());
      await Future.delayed(const Duration(milliseconds: 20));

      expect(events, hasLength(1));
      expect(events.first, isA<TuiModeActivated>());

      // Then deactivate
      detector.processOutput(rmcup());

      // Small delay to let the stream event propagate
      await Future.delayed(const Duration(milliseconds: 5));

      expect(detector.isActive, isFalse);
      expect(events, hasLength(2));
      expect(events.last, isA<TuiModeDeactivated>());
    });

    // @telos-scenario L1:...:tui_mode_detector:smcup-in-larger-output
    test('detects smcup embedded in larger output', () async {
      final output = Uint8List.fromList([
        ...'\x1b[Hsome terminal output'.codeUnits,
        ...smcup(),
        ...'\x1b[2J'.codeUnits,
      ]);

      detector.processOutput(output);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(detector.isActive, isTrue);
    });

    // @telos-scenario L1:...:tui_mode_detector:split-sequence
    test('detects sequence split across two chunks', () async {
      // Split smcup in the middle: ESC [ ? 1 0 | 4 9 h
      final part1 = Uint8List.fromList([0x1B, 0x5B, 0x3F, 0x31, 0x30]);
      final part2 = Uint8List.fromList([0x34, 0x39, 0x68]);

      detector.processOutput(part1);
      detector.processOutput(part2);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(detector.isActive, isTrue);
    });

    // @telos-scenario L1:...:tui_mode_detector:rapid-smcup-rmcup-debounce
    test('rapid smcup/rmcup pair is debounced (no activation)', () async {
      detector.processOutput(smcup());
      // Immediately send rmcup before debounce completes
      await Future.delayed(const Duration(milliseconds: 5));
      detector.processOutput(rmcup());

      await Future.delayed(const Duration(milliseconds: 20));

      // Should not have activated because rmcup cancelled the pending activation
      expect(detector.isActive, isFalse);
      expect(events, isEmpty);
    });

    // @telos-scenario L1:...:tui_mode_detector:triggering-command
    test('captures triggering command on activation', () async {
      detector.setLastCommand('vim file.txt');
      detector.processOutput(smcup());
      await Future.delayed(const Duration(milliseconds: 20));

      expect(events, hasLength(1));
      final event = events.first as TuiModeActivated;
      expect(event.triggeringCommand, equals('vim file.txt'));
    });

    // @telos-scenario L1:...:tui_mode_detector:multiple-smcup-idempotent
    test('multiple smcup sequences while active are idempotent', () async {
      detector.processOutput(smcup());
      await Future.delayed(const Duration(milliseconds: 20));
      detector.processOutput(smcup());
      await Future.delayed(const Duration(milliseconds: 20));

      expect(detector.isActive, isTrue);
      expect(events, hasLength(1)); // Only one activation event
    });

    // @telos-scenario L1:...:tui_mode_detector:rmcup-while-inactive
    test('rmcup while inactive does nothing', () {
      detector.processOutput(rmcup());

      expect(detector.isActive, isFalse);
      expect(events, isEmpty);
    });

    // @telos-scenario L1:...:tui_mode_detector:force-deactivate
    test('forceDeactivate works during active TUI mode', () async {
      detector.processOutput(smcup());
      await Future.delayed(const Duration(milliseconds: 20));
      expect(detector.isActive, isTrue);
      expect(events, hasLength(1));

      detector.forceDeactivate();

      // Small delay to let the stream event propagate
      await Future.delayed(const Duration(milliseconds: 5));

      expect(detector.isActive, isFalse);
      expect(events, hasLength(2));
      expect(events.last, isA<TuiModeDeactivated>());
    });

    // @telos-scenario L1:...:tui_mode_detector:force-deactivate-cancels-pending
    test('forceDeactivate cancels pending activation', () async {
      detector.processOutput(smcup());
      // Don't wait for debounce

      detector.forceDeactivate();
      await Future.delayed(const Duration(milliseconds: 20));

      // Should not have activated
      expect(detector.isActive, isFalse);
      expect(events, isEmpty);
    });

    // @telos-scenario L1:...:tui_mode_detector:reset
    test('reset clears all state', () async {
      detector.setLastCommand('vim');
      detector.processOutput(smcup());
      await Future.delayed(const Duration(milliseconds: 20));

      detector.reset();

      expect(detector.isActive, isFalse);
      // Note: reset doesn't emit events, it just clears state
    });

    // @telos-scenario L1:...:tui_mode_detector:string-input
    test('processOutputString works with string input', () async {
      detector.processOutputString('\x1b[?1049h');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(detector.isActive, isTrue);
    });

    // @telos-scenario L1:...:tui_mode_detector:events-stream
    test('events stream is broadcast (multiple listeners)', () async {
      final events2 = <TuiModeEvent>[];
      final sub2 = detector.events.listen(events2.add);

      detector.processOutput(smcup());
      await Future.delayed(const Duration(milliseconds: 20));

      expect(events, hasLength(1));
      expect(events2, hasLength(1));

      sub2.cancel();
    });
  });

  group('TuiModeEvent', () {
    // @telos-scenario L1:...:tui_mode_detector:event-types
    test('TuiModeActivated has optional triggering command', () {
      const event1 = TuiModeActivated();
      const event2 = TuiModeActivated(triggeringCommand: 'vim');

      expect(event1.triggeringCommand, isNull);
      expect(event2.triggeringCommand, equals('vim'));
    });
  });
}
