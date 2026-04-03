// @telos-test L1:function:lib/features/ai/domain/usecases:completeCommandLine

import 'package:bento/features/ai/data/services/unconfigured_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ai_config.dart';
import 'package:bento/features/ai/domain/entities/ai_failure.dart';
import 'package:bento/features/ai/domain/entities/ai_privacy_mode.dart';
import 'package:bento/features/ai/domain/entities/ai_suggestion.dart';
import 'package:bento/features/ai/domain/entities/shell_context.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:bento/features/ai/domain/usecases/complete_command_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiService extends Mock implements AiService {}

void main() {
  late MockAiService service;
  late CompleteCommandLine usecase;
  const shellContext = ShellContext(
    shell: 'bash',
    os: 'linux',
    cwd: '/workspace',
    availableCommands: ['aws', 'jq'],
    recentCommands: ['aws sts get-caller-identity'],
  );

  setUp(() {
    service = MockAiService();
    usecase = CompleteCommandLine(
      service: service,
      config: const AiConfig(mode: AiMode.remote),
    );
  });

  group('CompleteCommandLine', () {
    // @telos-scenario L1:function:lib/features/ai/domain/usecases:completeCommandLine:explicit-ai-completion-of-a-partial-line
    test('sends partial line and shell context and returns refined command suggestion',
        () async {
      when(() => service.isAvailable()).thenAnswer((_) async => true);
      when(() => service.privacyMode).thenReturn(AiPrivacyMode.remote);
      when(() => service.generateCommand(any())).thenAnswer(
        (_) async => const AiSuggestion(
          command: 'aws s3api list-objects --bucket my-bucket --query "Contents[].Key"',
          explanation: 'List object keys in the bucket',
          confidence: 0.82,
        ),
      );

      final result = await usecase.call(
        partialLine: 'aws s3api list-objects --bucket my-bucket',
        context: shellContext,
      );

      expect(result.isRight(), isTrue);
      final suggestion = result.getRight().toNullable()!;
      expect(suggestion.command, contains('--query'));
      expect(suggestion.privacyMode, AiPrivacyMode.remote);

      final captured = verify(() => service.generateCommand(captureAny())).captured.single as String;
      expect(captured, contains('Current partial line: aws s3api list-objects --bucket my-bucket'));
      expect(captured, contains('Shell: bash'));
      expect(captured, contains('OS: linux'));
    });

    // @telos-scenario L1:function:lib/features/ai/domain/usecases:completeCommandLine:ai-is-not-called-automatically-on-typing
    test('does not invoke AI until the explicit usecase is called', () async {
      verifyNever(() => service.generateCommand(any()));
    });

    // @telos-scenario L1:function:lib/features/ai/domain/usecases:completeCommandLine:privacy-mode-blocks-disallowed-provider-usage
    test('returns a private-mode suggestion when using a private service', () async {
      when(() => service.isAvailable()).thenAnswer((_) async => true);
      when(() => service.privacyMode).thenReturn(AiPrivacyMode.local);
      when(() => service.generateCommand(any())).thenAnswer(
        (_) async => const AiSuggestion(
          command: 'jq . file.json',
          explanation: 'Pretty-print JSON with jq',
          confidence: 0.9,
        ),
      );

      usecase = CompleteCommandLine(
        service: service,
        config: const AiConfig(mode: AiMode.local),
      );

      final result = await usecase.call(
        partialLine: 'jq file.json',
        context: shellContext,
        userIntent: 'pretty print the JSON',
      );

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable()!.privacyMode, AiPrivacyMode.local);
    });

    // @telos-scenario L1:function:lib/features/ai/domain/usecases:completeCommandLine:ai-returns-alternatives-for-ambiguous-intent
    test('returns alternatives for ambiguous partial line', () async {
      when(() => service.isAvailable()).thenAnswer((_) async => true);
      when(() => service.privacyMode).thenReturn(AiPrivacyMode.remote);
      when(() => service.generateCommand(any())).thenAnswer(
        (_) async => const AiSuggestion(
          command: 'find /var/log -type f',
          explanation: 'Find log files',
          confidence: 0.45,
          alternatives: ['find . -name "*.log"', 'journalctl -xe'],
        ),
      );

      final result = await usecase.call(
        partialLine: 'find logs',
        context: shellContext,
      );

      expect(result.isRight(), isTrue);
      expect(
        result.getRight().toNullable()!.alternatives,
        containsAll(['find . -name "*.log"', 'journalctl -xe']),
      );
    });

    // @telos-scenario L1:function:lib/features/ai/domain/usecases:completeCommandLine:empty-or-whitespace-line-is-rejected
    test('returns invalidInput for empty partialLine', () async {
      final result = await usecase.call(
        partialLine: '   ',
        context: shellContext,
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), const AIFailure.invalidInput('Partial command line is empty'));
      verifyNever(() => service.generateCommand(any()));
    });

    // @telos-scenario L1:function:lib/features/ai/domain/usecases:completeCommandLine:privacy-mode-blocks-disallowed-provider-usage
    test('blocks disallowed provider usage when config and service privacy modes differ', () async {
      when(() => service.isAvailable()).thenAnswer((_) async => true);
      when(() => service.privacyMode).thenReturn(AiPrivacyMode.cloud);

      usecase = CompleteCommandLine(
        service: service,
        config: const AiConfig(mode: AiMode.local),
      );

      final result = await usecase.call(
        partialLine: 'jq file.json',
        context: shellContext,
      );

      expect(result.getLeft().toNullable(), const AIFailure.providerUnavailable());
      verifyNever(() => service.generateCommand(any()));
    });

    test('maps unavailable service to providerUnavailable', () async {
      when(() => service.isAvailable()).thenAnswer((_) async => false);

      final result = await usecase.call(
        partialLine: 'git st',
        context: shellContext,
      );

      expect(result.getLeft().toNullable(), const AIFailure.providerUnavailable());
    });

    test('maps unconfigured service exception to providerUnavailable', () async {
      when(() => service.isAvailable()).thenAnswer((_) async => true);
      when(() => service.privacyMode).thenReturn(AiPrivacyMode.remote);
      when(() => service.generateCommand(any())).thenThrow(
        const AiNotConfiguredException(),
      );

      final result = await usecase.call(
        partialLine: 'git st',
        context: shellContext,
      );

      expect(result.getLeft().toNullable(), const AIFailure.providerUnavailable());
    });
  });
}
