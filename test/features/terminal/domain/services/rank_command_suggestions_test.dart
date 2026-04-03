// @telos-test L1:function:lib/features/terminal/domain/services:rankCommandSuggestions

import 'dart:ui';

import 'package:bento/features/terminal/domain/entities/command_knowledge.dart';
import 'package:bento/features/terminal/domain/entities/command_suggestion_chip.dart';
import 'package:bento/features/terminal/domain/entities/prompt_input_state.dart';
import 'package:bento/features/terminal/domain/services/rank_command_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rankCommandSuggestions', () {
    const knowledge = CommandKnowledge();

    // @telos-scenario L1:function:lib/features/terminal/domain/services:rankCommandSuggestions:show-idle-suggestions-when-prompt-is-empty
    test('returns recent history plus common commands when input is empty', () {
      final results = rankCommandSuggestions(
        inputState: _state(text: '', cursorOffset: 0),
        history: const [
          HistoryEntry(command: 'kubectl get pods -n production', useCount: 3),
        ],
        knowledge: knowledge,
      );

      expect(results, isNotEmpty);
      expect(results.first.label, 'kubectl get pods -n production');
      expect(results.any((s) => s.label == 'git'), isTrue);
      expect(results.length, lessThanOrEqualTo(12));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:rankCommandSuggestions:rank-history-above-generic-commands-for-same-prefix
    test('history suggestion outranks command knowledge for shared prefix', () {
      final results = rankCommandSuggestions(
        inputState: _state(text: 'kub', cursorOffset: 3),
        history: const [
          HistoryEntry(command: 'kubectl get pods -n production', useCount: 5),
        ],
        knowledge: knowledge,
      );

      expect(results, isNotEmpty);
      expect(results.first.kind, CommandSuggestionKind.history);
      expect(results.first.label, 'kubectl get pods -n production');
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:rankCommandSuggestions:suggest-known-subcommands-after-a-command-and-space
    test('docker space suggests first-level subcommands', () {
      final results = rankCommandSuggestions(
        inputState: _state(text: 'docker ', cursorOffset: 7),
        history: const [],
        knowledge: knowledge,
      );

      expect(results.any((s) => s.label == 'run'), isTrue);
      expect(results.any((s) => s.label == 'ps'), isTrue);
      expect(results.any((s) => s.label == 'compose'), isTrue);
      expect(
        results
            .where((s) => ['run', 'ps', 'compose'].contains(s.label))
            .every((s) => s.kind == CommandSuggestionKind.subcommand),
        isTrue,
      );
    });

    test('docker co suggests first-level subcommand completions for partial second token', () {
      final results = rankCommandSuggestions(
        inputState: _state(text: 'docker co', cursorOffset: 9),
        history: const [],
        knowledge: knowledge,
      );

      expect(results.any((s) => s.label == 'compose'), isTrue);
      expect(
        results.firstWhere((s) => s.label == 'compose').kind,
        CommandSuggestionKind.subcommand,
      );
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:rankCommandSuggestions:suggest-nested-arguments-after-known-command-context
    test('kubectl get space suggests nested resources with active token range', () {
      final results = rankCommandSuggestions(
        inputState: _state(text: 'kubectl get ', cursorOffset: 12),
        history: const [],
        knowledge: knowledge,
      );

      final pods = results.firstWhere((s) => s.label == 'pods');
      expect(results.any((s) => s.label == 'services'), isTrue);
      expect(results.any((s) => s.label == 'deployments'), isTrue);
      expect(pods.kind, CommandSuggestionKind.argument);
      expect(pods.replacementRange, const TextRange(start: 12, end: 12));
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:rankCommandSuggestions:deduplicate-identical-labels-from-multiple-sources
    test('deduplicates identical labels and keeps higher-priority source', () {
      final results = rankCommandSuggestions(
        inputState: _state(text: 'git', cursorOffset: 3),
        history: const [HistoryEntry(command: 'git', useCount: 10)],
        knowledge: knowledge,
        snippets: const ['git'],
      );

      expect(results.where((s) => s.label == 'git').length, 1);
      expect(results.first.label, 'git');
      expect(results.first.kind, CommandSuggestionKind.snippet);
    });

    // @telos-scenario L1:function:lib/features/terminal/domain/services:rankCommandSuggestions:do-not-suggest-when-ribbon-cannot-be-shown
    test('returns empty list when canShowRibbon is false', () {
      final results = rankCommandSuggestions(
        inputState: const PromptInputState(
          text: 'git',
          cursorOffset: 3,
          isAtPrompt: true,
          isEditing: true,
          isInTuiMode: false,
          canShowRibbon: false,
        ),
        history: const [HistoryEntry(command: 'git status')],
        knowledge: knowledge,
      );

      expect(results, isEmpty);
    });
  });
}

PromptInputState _state({
  required String text,
  required int cursorOffset,
}) {
  return PromptInputState(
    text: text,
    cursorOffset: cursorOffset,
    isAtPrompt: true,
    isEditing: true,
    isInTuiMode: false,
    canShowRibbon: true,
  );
}
