// @telos-test L1:function:lib/features/ai/domain/usecases:completeCommandLine

import 'package:bento/features/ai/domain/entities/ai_failure.dart';
import 'package:bento/features/ai/domain/entities/ai_privacy_mode.dart';
import 'package:bento/features/ai/domain/entities/command_suggestion.dart';
import 'package:bento/features/ai/presentation/widgets/ai_line_completion_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('AiLineCompletionSheet', () {
    testWidgets('loads suggestion, allows alternative selection, and applies',
        (tester) async {
      String? appliedCommand;
      String? ranCommand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiLineCompletionSheet(
              originalLine: 'git chec main',
              onGenerate: () async => const Right(
                CommandSuggestion(
                  command: 'git checkout main',
                  explanation: 'Complete the checkout command',
                  confidence: 0.88,
                  privacyMode: AiPrivacyMode.remote,
                  alternatives: ['git switch main'],
                ),
              ),
              onApply: (command) => appliedCommand = command,
              onRun: (command) => ranCommand = command,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('current-line')), findsOneWidget);
      expect(find.byKey(const Key('suggested-command')), findsOneWidget);
      expect(find.text('git checkout main'), findsOneWidget);

      await tester.tap(find.text('git switch main'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply to line'));
      await tester.pumpAndSettle();

      expect(appliedCommand, 'git switch main');
      expect(ranCommand, isNull);
    });

    testWidgets('run uses the selected suggestion', (tester) async {
      String? ranCommand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiLineCompletionSheet(
              originalLine: 'aws s3 ls',
              onGenerate: () async => const Right(
                CommandSuggestion(
                  command: 'aws s3api list-buckets',
                  explanation: 'List buckets with API output',
                  confidence: 0.79,
                  privacyMode: AiPrivacyMode.cloud,
                ),
              ),
              onApply: (_) {},
              onRun: (command) => ranCommand = command,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      expect(ranCommand, 'aws s3api list-buckets');
    });

    testWidgets('shows error state when generation fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiLineCompletionSheet(
              originalLine: 'find logs',
              onGenerate: () async =>
                  const Left(AIFailure.inferenceError('No suggestion available')),
              onApply: (_) {},
              onRun: (_) {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error-text')), findsOneWidget);
      expect(find.text('No suggestion available'), findsOneWidget);
    });
  });
}
