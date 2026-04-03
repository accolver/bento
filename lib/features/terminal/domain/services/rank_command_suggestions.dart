// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions

import 'dart:math' as math;
import 'dart:ui';

import '../entities/command_knowledge.dart';
import '../entities/command_suggestion_chip.dart';
import '../entities/prompt_input_state.dart';

/// Lightweight history record used by the command ranking engine.
class HistoryEntry {
  const HistoryEntry({
    required this.command,
    this.useCount = 1,
    this.lastUsed,
  });

  final String command;
  final int useCount;
  final DateTime? lastUsed;
}

/// Result of tokenizing prompt input around the current cursor.
class ActiveToken {
  const ActiveToken({
    required this.range,
    required this.token,
  });

  final TextRange range;
  final String token;
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> rankCommandSuggestions({
  required PromptInputState inputState,
  required List<HistoryEntry> history,
  required CommandKnowledge knowledge,
  List<String> snippets = const [],
  List<String> symbols = const [],
  int maxSuggestions = 12,
}) {
  if (!inputState.canShowRibbon || inputState.isInTuiMode) {
    return const [];
  }

  final safeMax = math.max(0, maxSuggestions);
  if (safeMax == 0) {
    return const [];
  }

  final token = _activeToken(inputState.text, inputState.cursorOffset);
  final text = inputState.text;
  final trimmedLeft = text.trimLeft();

  if (trimmedLeft.isEmpty) {
    return _idleSuggestions(history, safeMax);
  }

  final beforeCursor = text.substring(
    0,
    _clampOffset(inputState.cursorOffset, text.length),
  );
  final endsWithSpace =
      beforeCursor.isNotEmpty && RegExp(r'\s$').hasMatch(beforeCursor);
  final tokens = beforeCursor.trim().isEmpty
      ? <String>[]
      : beforeCursor.trim().split(RegExp(r'\s+'));

  final suggestions = <CommandSuggestionChip>[
    ..._snippetSuggestions(snippets, token),
    ..._historySuggestions(history, token),
  ];

  if (tokens.length <= 1 && !endsWithSpace) {
    suggestions.addAll(_commandSuggestions(token, knowledge));
  } else if (tokens.isNotEmpty) {
    final baseCommand = tokens.first;
    if (tokens.length == 1 || (tokens.length == 2 && !endsWithSpace)) {
      suggestions.addAll(_subcommandSuggestions(baseCommand, token, knowledge));
    } else {
      final subcommand = tokens[1];
      suggestions.addAll(
        _nestedSuggestions(baseCommand, subcommand, token, knowledge),
      );
    }
  }

  suggestions.addAll(_symbolSuggestions(symbols, token));

  return _deduplicateAndSort(suggestions).take(safeMax).toList();
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> _idleSuggestions(
  List<HistoryEntry> history,
  int maxSuggestions,
) {
  const defaults = ['ls', 'cd', 'git', 'ssh', 'docker'];

  final suggestions = <CommandSuggestionChip>[
    ...history.take(maxSuggestions).map(
          (entry) => CommandSuggestionChip(
            id: 'history:${entry.command}',
            kind: CommandSuggestionKind.history,
            label: entry.command,
            insertText: entry.command,
            replacementRange: const TextRange(start: 0, end: 0),
            priority: 1000 + entry.useCount,
          ),
        ),
    ...defaults.map(
      (command) => CommandSuggestionChip(
        id: 'command:$command',
        kind: CommandSuggestionKind.command,
        label: command,
        insertText: command,
        replacementRange: const TextRange(start: 0, end: 0),
        appendSpace: true,
        priority: 500,
      ),
    ),
  ];

  return _deduplicateAndSort(suggestions).take(maxSuggestions).toList();
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> _snippetSuggestions(
  List<String> snippets,
  ActiveToken token,
) {
  if (snippets.isEmpty) {
    return const [];
  }

  return snippets
      .where((snippet) => snippet.startsWith(token.token))
      .map(
        (snippet) => CommandSuggestionChip(
          id: 'snippet:$snippet',
          kind: CommandSuggestionKind.snippet,
          label: snippet,
          insertText: snippet,
          replacementRange: token.range,
          appendSpace: true,
          priority: 1200,
        ),
      )
      .toList();
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> _historySuggestions(
  List<HistoryEntry> history,
  ActiveToken token,
) {
  return history
      .where((entry) => entry.command.startsWith(token.token))
      .map(
        (entry) => CommandSuggestionChip(
          id: 'history:${entry.command}',
          kind: CommandSuggestionKind.history,
          label: entry.command,
          insertText: entry.command,
          replacementRange: token.range,
          priority: 1000 + entry.useCount,
        ),
      )
      .toList();
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> _commandSuggestions(
  ActiveToken token,
  CommandKnowledge knowledge,
) {
  return knowledge.commands
      .where((command) => command.startsWith(token.token))
      .map(
        (command) => CommandSuggestionChip(
          id: 'command:$command',
          kind: CommandSuggestionKind.command,
          label: command,
          insertText: command,
          replacementRange: token.range,
          appendSpace: true,
          priority: 800,
        ),
      )
      .toList();
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> _subcommandSuggestions(
  String command,
  ActiveToken token,
  CommandKnowledge knowledge,
) {
  final subcommands = knowledge.subcommandsFor(command) ?? const [];
  return subcommands
      .where(
        (subcommand) =>
            token.token.isEmpty || subcommand.startsWith(token.token),
      )
      .map(
        (subcommand) => CommandSuggestionChip(
          id: 'subcommand:$command:$subcommand',
          kind: CommandSuggestionKind.subcommand,
          label: subcommand,
          insertText: subcommand,
          replacementRange: token.range,
          appendSpace: true,
          priority: 700,
        ),
      )
      .toList();
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> _nestedSuggestions(
  String command,
  String subcommand,
  ActiveToken token,
  CommandKnowledge knowledge,
) {
  final nested = knowledge.nestedSubcommandsFor(command, subcommand) ?? const [];
  return nested
      .where(
        (argument) => token.token.isEmpty || argument.startsWith(token.token),
      )
      .map(
        (argument) => CommandSuggestionChip(
          id: 'argument:$command:$subcommand:$argument',
          kind: CommandSuggestionKind.argument,
          label: argument,
          insertText: argument,
          replacementRange: token.range,
          appendSpace: true,
          priority: 650,
        ),
      )
      .toList();
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> _symbolSuggestions(
  List<String> symbols,
  ActiveToken token,
) {
  if (symbols.isEmpty) {
    return const [];
  }

  return symbols
      .where((symbol) => token.token.isEmpty || symbol.startsWith(token.token))
      .map(
        (symbol) => CommandSuggestionChip(
          id: 'symbol:$symbol',
          kind: CommandSuggestionKind.symbol,
          label: symbol,
          insertText: symbol,
          replacementRange: token.range,
          priority: 100,
        ),
      )
      .toList();
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
List<CommandSuggestionChip> _deduplicateAndSort(
  List<CommandSuggestionChip> suggestions,
) {
  final deduplicated = <String, CommandSuggestionChip>{};

  for (final suggestion in suggestions) {
    final existing = deduplicated[suggestion.label];
    if (existing == null || suggestion.priority > existing.priority) {
      deduplicated[suggestion.label] = suggestion;
    }
  }

  final results = deduplicated.values.toList()
    ..sort((a, b) => b.priority.compareTo(a.priority));
  return results;
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
ActiveToken _activeToken(String text, int cursorOffset) {
  final cursor = _clampOffset(cursorOffset, text.length);
  var start = cursor;
  var end = cursor;

  while (start > 0 && !_isWhitespace(text.codeUnitAt(start - 1))) {
    start -= 1;
  }

  while (end < text.length && !_isWhitespace(text.codeUnitAt(end))) {
    end += 1;
  }

  return ActiveToken(
    range: TextRange(start: start, end: end),
    token: text.substring(start, end),
  );
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
int _clampOffset(int offset, int length) {
  return math.max(0, math.min(offset, length));
}

// @telos L1:function:lib/features/terminal/domain/services:rankCommandSuggestions
bool _isWhitespace(int codeUnit) {
  return codeUnit == 32 || codeUnit == 9 || codeUnit == 10 || codeUnit == 13;
}
