// @telos L2:contract:component-command-ribbon

import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/command_knowledge.dart';
import '../../domain/entities/command_suggestion_chip.dart';
import '../../domain/services/rank_command_suggestions.dart';
import 'block_provider.dart';
import 'prompt_input_controller.dart';

/// UI mode for the command ribbon.
enum CommandRibbonUiMode {
  ranked,
  symbols,
}

final commandRibbonUiModeProvider =
    StateProvider.family<CommandRibbonUiMode, String>(
  (ref, sessionId) => CommandRibbonUiMode.ranked,
);

final commandRibbonSuggestionsProvider =
    Provider.family<List<CommandSuggestionChip>, String>((ref, sessionId) {
  final inputState = ref.watch(promptInputControllerProvider(sessionId));
  final uiMode = ref.watch(commandRibbonUiModeProvider(sessionId));
  final blockState = ref.watch(blockListControllerProvider(sessionId));

  final history = blockState.blocks.reversed
      .map((block) => HistoryEntry(command: block.command))
      .toList();

  if (uiMode == CommandRibbonUiMode.symbols) {
    return CommandKnowledge.symbols
        .map(
          (symbol) => CommandSuggestionChip(
            id: 'symbol:$symbol',
            kind: CommandSuggestionKind.symbol,
            label: symbol,
            insertText: symbol,
            replacementRange: TextRange(
              start: inputState.cursorOffset,
              end: inputState.cursorOffset,
            ),
            priority: 100,
          ),
        )
        .toList();
  }

  return rankCommandSuggestions(
    inputState: inputState,
    history: history,
    knowledge: const CommandKnowledge(),
    symbols: const [],
  ).toList();
});
