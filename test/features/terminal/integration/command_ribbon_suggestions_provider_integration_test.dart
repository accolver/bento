// @telos-test L1:function:lib/features/terminal/domain/services:rankCommandSuggestions

import 'package:bento/features/terminal/presentation/providers/block_provider.dart';
import 'package:bento/features/terminal/presentation/providers/command_ribbon_ui_provider.dart';
import 'package:bento/features/terminal/presentation/providers/prompt_input_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('commandRibbonSuggestionsProvider', () {
    test('uses prompt state and history from blocks', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final promptController =
          container.read(promptInputControllerProvider('session-1').notifier);
      final blockController =
          container.read(blockListControllerProvider('session-1').notifier);

      promptController.onPromptDetected();
      blockController.createBlock('kubectl get pods -n production');
      blockController.completeBlock();
      promptController.insertText('kub');

      final suggestions =
          container.read(commandRibbonSuggestionsProvider('session-1'));

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.label, 'kubectl get pods -n production');
    });

    test('symbol mode returns symbol suggestions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(promptInputControllerProvider('session-1').notifier)
          .onPromptDetected();
      container.read(commandRibbonUiModeProvider('session-1').notifier).state =
          CommandRibbonUiMode.symbols;

      final suggestions =
          container.read(commandRibbonSuggestionsProvider('session-1'));

      expect(suggestions, isNotEmpty);
      expect(suggestions.every((s) => s.label.isNotEmpty), isTrue);
      expect(suggestions.any((s) => s.label == '|'), isTrue);
    });
  });
}
