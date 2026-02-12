// @telos L2:contract:component-command-ribbon

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/command_knowledge.dart';
import 'block_provider.dart';

part 'command_ribbon_provider.freezed.dart';
part 'command_ribbon_provider.g.dart';

/// The type of a ribbon suggestion, used for styling and iconography.
enum RibbonSuggestionType {
  /// A command recalled from session history.
  history,

  /// A known subcommand for the current base command.
  subcommand,

  /// A shell symbol (pipe, redirect, etc.).
  symbol,

  /// A commonly-used command shown as a default.
  common,
}

/// Represents a single suggestion chip in the command ribbon.
@freezed
class RibbonSuggestion with _$RibbonSuggestion {
  const factory RibbonSuggestion({
    /// Display text shown on the chip.
    required String text,

    /// Category of this suggestion (affects styling).
    required RibbonSuggestionType type,

    /// The full text to insert into the input field.
    /// May differ from [text] (e.g. appending a trailing space).
    String? insertText,
  }) = _RibbonSuggestion;
}

/// The current operating mode of the ribbon.
enum RibbonMode {
  /// No input — showing history or default commands.
  idle,

  /// User is typing — showing contextual completions.
  completing,

  /// Symbol tray is open.
  symbols,
}

/// Immutable state for the command ribbon.
@freezed
class RibbonState with _$RibbonState {
  const factory RibbonState({
    /// Ordered list of suggestions to display.
    @Default([]) List<RibbonSuggestion> suggestions,

    /// Current ribbon mode.
    @Default(RibbonMode.idle) RibbonMode mode,

    /// The raw input text that produced the current suggestions.
    @Default('') String currentInput,
  }) = _RibbonState;
}

/// Controls the command ribbon suggestions based on current terminal input.
///
/// Keyed by [sessionId] so each terminal session has its own ribbon state.
/// Maintains an in-memory command history (up to [_maxHistory] entries) and
/// combines it with [CommandKnowledge] to produce ranked suggestions.
@Riverpod(keepAlive: true)
class CommandRibbonController extends _$CommandRibbonController {
  /// In-memory command history, most-recent first.
  final List<String> _commandHistory = [];

  /// Maximum number of history entries to retain.
  static const _maxHistory = 100;

  @override
  RibbonState build(String sessionId) {
    return RibbonState(
      suggestions: _getIdleSuggestions(),
    );
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Recomputes suggestions based on the current [input] text.
  ///
  /// Called on every keystroke (the widget layer should debounce if needed).
  void onInputChanged(String input) {
    if (input.isEmpty) {
      state = RibbonState(
        suggestions: _getIdleSuggestions(),
      );
      return;
    }

    final parts = input.trimLeft().split(RegExp(r'\s+'));
    final command = parts.first;

    if (parts.length == 1 && !input.endsWith(' ')) {
      // Still typing the base command name.
      state = RibbonState(
        suggestions: _getCommandCompletions(command),
        mode: RibbonMode.completing,
        currentInput: input,
      );
    } else if (parts.length == 2 && !input.endsWith(' ')) {
      // Typing the first subcommand / argument.
      _completingSubcommand(command, parts[1], input);
    } else if (parts.length >= 2 && input.endsWith(' ')) {
      // Just pressed space — show full subcommand list.
      _afterSpace(command, parts, input);
    } else {
      // Deeper arguments — fall back to history matching.
      state = RibbonState(
        suggestions: _getHistoryMatches(input),
        mode: RibbonMode.completing,
        currentInput: input,
      );
    }
  }

  /// Switches the ribbon into symbol-tray mode.
  void showSymbols() {
    state = RibbonState(
      suggestions: CommandKnowledge.symbols
          .map(
            (s) => RibbonSuggestion(
              text: s,
              type: RibbonSuggestionType.symbol,
              insertText: s,
            ),
          )
          .toList(),
      mode: RibbonMode.symbols,
      currentInput: state.currentInput,
    );
  }

  /// Exits symbol-tray mode and returns to input-based suggestions.
  void hideSymbols() {
    onInputChanged(state.currentInput);
  }

  /// Records [command] in the in-memory history for future suggestions.
  void recordCommand(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    // Move to front (most-recent-first), deduplicating.
    _commandHistory
      ..remove(trimmed)
      ..insert(0, trimmed);
    if (_commandHistory.length > _maxHistory) {
      _commandHistory.removeLast();
    }
  }

  /// Seeds the history from existing blocks in the given [sessionId].
  ///
  /// Safe to call before blocks are loaded — failures are silently ignored.
  void loadHistoryFromBlocks(String sessionId) {
    try {
      final blockState = ref.read(blockListControllerProvider(sessionId));
      for (final block in blockState.blocks.reversed) {
        final cmd = block.command.trim();
        if (cmd.isNotEmpty && !_commandHistory.contains(cmd)) {
          _commandHistory.add(cmd);
        }
      }
    } on Exception catch (_) {
      // Block provider might not be initialised yet — that's fine.
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Suggestions shown when the input field is empty.
  List<RibbonSuggestion> _getIdleSuggestions() {
    final historySuggestions = _commandHistory
        .take(8)
        .map(
          (cmd) => RibbonSuggestion(
            text: cmd,
            type: RibbonSuggestionType.history,
            insertText: cmd,
          ),
        )
        .toList();

    if (historySuggestions.isNotEmpty) return historySuggestions;

    // Sensible defaults for a fresh session.
    return const [
      RibbonSuggestion(
        text: 'ls',
        type: RibbonSuggestionType.common,
        insertText: 'ls',
      ),
      RibbonSuggestion(
        text: 'cd',
        type: RibbonSuggestionType.common,
        insertText: 'cd ',
      ),
      RibbonSuggestion(
        text: 'cat',
        type: RibbonSuggestionType.common,
        insertText: 'cat ',
      ),
      RibbonSuggestion(
        text: 'grep',
        type: RibbonSuggestionType.common,
        insertText: 'grep ',
      ),
      RibbonSuggestion(
        text: 'sudo',
        type: RibbonSuggestionType.common,
        insertText: 'sudo ',
      ),
      RibbonSuggestion(
        text: 'ssh',
        type: RibbonSuggestionType.common,
        insertText: 'ssh ',
      ),
      RibbonSuggestion(
        text: 'docker',
        type: RibbonSuggestionType.common,
        insertText: 'docker ',
      ),
      RibbonSuggestion(
        text: 'git',
        type: RibbonSuggestionType.common,
        insertText: 'git ',
      ),
    ];
  }

  /// Completions for a partially-typed base command.
  List<RibbonSuggestion> _getCommandCompletions(String prefix) {
    final results = <RibbonSuggestion>[];

    // History matches first (higher priority).
    for (final cmd in _commandHistory) {
      final firstWord = cmd.split(' ').first;
      if (firstWord.startsWith(prefix) && firstWord != prefix) {
        results.add(
          RibbonSuggestion(
            text: firstWord,
            type: RibbonSuggestionType.history,
            insertText: firstWord,
          ),
        );
      }
      // Also suggest full commands from history.
      if (cmd.startsWith(prefix) && cmd != prefix) {
        results.add(
          RibbonSuggestion(
            text: cmd,
            type: RibbonSuggestionType.history,
            insertText: cmd,
          ),
        );
      }
    }

    // Known commands from the knowledge base.
    for (final cmd in CommandKnowledge.subcommands.keys) {
      if (cmd.startsWith(prefix) && !results.any((r) => r.text == cmd)) {
        results.add(
          RibbonSuggestion(
            text: cmd,
            type: RibbonSuggestionType.common,
            insertText: '$cmd ',
          ),
        );
      }
    }

    // Deduplicate by display text.
    final seen = <String>{};
    return results.where((r) => seen.add(r.text)).take(10).toList();
  }

  /// History entries whose full text starts with [prefix].
  List<RibbonSuggestion> _getHistoryMatches(String prefix) {
    return _commandHistory
        .where((cmd) => cmd.startsWith(prefix) && cmd != prefix)
        .take(8)
        .map(
          (cmd) => RibbonSuggestion(
            text: cmd,
            type: RibbonSuggestionType.history,
            insertText: cmd,
          ),
        )
        .toList();
  }

  /// Handles the case where the user is partially typing a subcommand.
  void _completingSubcommand(
    String command,
    String partialSub,
    String input,
  ) {
    final subcommands = CommandKnowledge.getSubcommands(command);
    if (subcommands != null) {
      final filtered = subcommands
          .where((s) => s.startsWith(partialSub))
          .map(
            (s) => RibbonSuggestion(
              text: s,
              type: RibbonSuggestionType.subcommand,
              insertText: s,
            ),
          )
          .toList();
      state = RibbonState(
        suggestions: filtered.isEmpty ? _getHistoryMatches(input) : filtered,
        mode: RibbonMode.completing,
        currentInput: input,
      );
    } else {
      state = RibbonState(
        suggestions: _getHistoryMatches(input),
        mode: RibbonMode.completing,
        currentInput: input,
      );
    }
  }

  /// Handles the case where the user just pressed space after a command/sub.
  void _afterSpace(String command, List<String> parts, String input) {
    final subcommands = CommandKnowledge.getSubcommands(command);

    if (subcommands != null && parts.length == 2) {
      // Show first-level subcommands.
      state = RibbonState(
        suggestions: subcommands
            .map(
              (s) => RibbonSuggestion(
                text: s,
                type: RibbonSuggestionType.subcommand,
                insertText: s,
              ),
            )
            .toList(),
        mode: RibbonMode.completing,
        currentInput: input,
      );
    } else if (parts.length == 3) {
      // Try nested subcommands (e.g. `kubectl get <resource>`).
      final nested = CommandKnowledge.getNestedSubcommands(command, parts[1]);
      if (nested != null) {
        state = RibbonState(
          suggestions: nested
              .map(
                (s) => RibbonSuggestion(
                  text: s,
                  type: RibbonSuggestionType.subcommand,
                  insertText: s,
                ),
              )
              .toList(),
          mode: RibbonMode.completing,
          currentInput: input,
        );
      } else {
        state = RibbonState(
          suggestions: _getHistoryMatches(input),
          mode: RibbonMode.completing,
          currentInput: input,
        );
      }
    } else {
      state = RibbonState(
        suggestions: _getHistoryMatches(input),
        mode: RibbonMode.completing,
        currentInput: input,
      );
    }
  }
}
