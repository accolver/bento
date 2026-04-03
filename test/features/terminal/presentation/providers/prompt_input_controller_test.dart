// @telos-test L1:function:lib/features/terminal/presentation/providers:prompt_input_controller
// ignore_for_file: cascade_invocations

import 'dart:ui';

import 'package:bento/features/terminal/presentation/providers/prompt_input_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('PromptInputController', () {
    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:enter-prompt-state-after-shell-prompt-detected
    test('onPromptDetected enters editable prompt state and enables ribbon', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier.onPromptDetected();

      final state = container.read(provider);
      expect(state.isAtPrompt, isTrue);
      expect(state.canShowRibbon, isTrue);
      expect(state.isEditing, isTrue);
      expect(state.text, isEmpty);
      expect(state.cursorOffset, 0);
    });

    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:hide-ribbon-when-command-starts-running
    test('onCommandStarted clears prompt state and hides ribbon', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier
        ..onPromptDetected()
        ..insertText('kubectl get pods')
        ..onCommandStarted();

      final state = container.read(provider);

      expect(state.isAtPrompt, isFalse);
      expect(state.canShowRibbon, isFalse);
      expect(state.text, isEmpty);
      expect(state.cursorOffset, 0);
    });

    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:disable-prompt-tracking-during-tui-mode
    test('onTuiModeEntered disables ribbon and completion state', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier
        ..onPromptDetected()
        ..insertText('vim README.md')
        ..onTuiModeEntered();

      final state = container.read(provider);

      expect(state.isInTuiMode, isTrue);
      expect(state.canShowRibbon, isFalse);
      expect(state.isAtPrompt, isFalse);
      expect(state.isEditing, isFalse);
    });

    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:disable-prompt-tracking-during-tui-mode
    test('onTuiModeExited waits for next prompt detection', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier
        ..onTuiModeEntered()
        ..onTuiModeExited();

      final state = container.read(provider);

      expect(state.isInTuiMode, isFalse);
      expect(state.canShowRibbon, isFalse);
      expect(state.isAtPrompt, isFalse);
      expect(state.text, isEmpty);
    });

    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:insert-text-at-cursor-position
    test('insertText inserts at current cursor and advances offset', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier
        ..onPromptDetected()
        ..insertText('kubectl get ')
        ..insertText('pods');

      final state = container.read(provider);
      expect(state.text, 'kubectl get pods');
      expect(state.cursorOffset, 16);
    });

    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:replace-only-active-token-range
    test('replaceRange replaces token and preserves surrounding text', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier
        ..onPromptDetected()
        ..insertText('kub get pods')
        ..replaceRange(const TextRange(start: 0, end: 3), 'kubectl');

      final state = container.read(provider);
      expect(state.text, 'kubectl get pods');
      expect(state.cursorOffset, 7);
    });

    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:backspace-updates-text-safely-at-start-of-line
    test('deleteBackward at offset 0 is a no-op', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier
        ..onPromptDetected()
        ..deleteBackward();

      final state = container.read(provider);
      expect(state.text, isEmpty);
      expect(state.cursorOffset, 0);
    });

    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:cursor-movement-is-clamped-to-valid-range
    test('moveCursor clamps to text length upper bound', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier
        ..onPromptDetected()
        ..insertText('git status')
        ..moveCursor(999);

      final state = container.read(provider);
      expect(state.cursorOffset, state.text.length);
    });

    // @telos-scenario L1:function:lib/features/terminal/presentation/providers:prompt_input_controller:cursor-movement-is-clamped-to-valid-range
    test('moveCursor clamps to zero lower bound', () {
      final provider = promptInputControllerProvider('session-1');
      final notifier = container.read(provider.notifier);

      notifier
        ..onPromptDetected()
        ..insertText('git status')
        ..moveCursor(-5);

      final state = container.read(provider);
      expect(state.cursorOffset, 0);
    });
  });
}
