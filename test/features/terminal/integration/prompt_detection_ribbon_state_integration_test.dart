// @telos-test L1:function:lib/features/terminal/presentation/providers:prompt_input_controller

import 'package:bento/features/terminal/presentation/providers/output_router_provider.dart';
import 'package:bento/features/terminal/presentation/providers/prompt_input_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prompt detection -> ribbon state integration', () {
    test('prompt -> command submit -> next prompt toggles ribbon-ready state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(
        outputRouterControllerProvider('session-1').notifier,
      );

      router.processOutput('user@host:~\$ \n');

      var promptState = container.read(promptInputControllerProvider('session-1'));
      expect(promptState.isAtPrompt, isTrue);
      expect(promptState.canShowRibbon, isTrue);

      router.processInput('l');
      router.processInput('s');
      router.processInput('\r');

      promptState = container.read(promptInputControllerProvider('session-1'));
      expect(promptState.isAtPrompt, isFalse);
      expect(promptState.canShowRibbon, isFalse);

      router.processOutput('file.txt\n');
      router.processOutput('user@host:~\$ \n');

      promptState = container.read(promptInputControllerProvider('session-1'));
      expect(promptState.isAtPrompt, isTrue);
      expect(promptState.canShowRibbon, isTrue);
    });

    test('tui enter and exit suppresses ribbon state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(
        outputRouterControllerProvider('session-1').notifier,
      );

      router.processOutput('user@host:~\$ \n');
      router.processOutput('\x1b[?1049h');
      await Future<void>.delayed(const Duration(milliseconds: 130));

      var promptState = container.read(promptInputControllerProvider('session-1'));
      expect(promptState.isInTuiMode, isTrue);
      expect(promptState.canShowRibbon, isFalse);

      router.processOutput('\x1b[?1049l');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      promptState = container.read(promptInputControllerProvider('session-1'));
      expect(promptState.isInTuiMode, isFalse);
    });
  });
}
