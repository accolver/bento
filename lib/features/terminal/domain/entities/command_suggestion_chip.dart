// @telos L2:contract:component-command-ribbon

import 'dart:ui';

/// Kinds of deterministic command-ribbon suggestions.
enum CommandSuggestionKind {
  history,
  command,
  subcommand,
  argument,
  file,
  snippet,
  symbol,
  ai,
}

/// A structured command-ribbon suggestion with explicit replacement semantics.
class CommandSuggestionChip {
  const CommandSuggestionChip({
    required this.id,
    required this.kind,
    required this.label,
    required this.insertText,
    required this.replacementRange,
    this.description,
    this.trailingText,
    this.isAi = false,
    this.appendSpace = false,
    this.priority = 0,
  });

  final String id;
  final CommandSuggestionKind kind;
  final String label;
  final String insertText;
  final TextRange replacementRange;
  final String? description;
  final String? trailingText;
  final bool isAi;
  final bool appendSpace;
  final int priority;

  CommandSuggestionChip copyWith({
    String? id,
    CommandSuggestionKind? kind,
    String? label,
    String? insertText,
    TextRange? replacementRange,
    String? description,
    String? trailingText,
    bool? isAi,
    bool? appendSpace,
    int? priority,
  }) {
    return CommandSuggestionChip(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      insertText: insertText ?? this.insertText,
      replacementRange: replacementRange ?? this.replacementRange,
      description: description ?? this.description,
      trailingText: trailingText ?? this.trailingText,
      isAi: isAi ?? this.isAi,
      appendSpace: appendSpace ?? this.appendSpace,
      priority: priority ?? this.priority,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CommandSuggestionChip &&
        other.id == id &&
        other.kind == kind &&
        other.label == label &&
        other.insertText == insertText &&
        other.replacementRange == replacementRange &&
        other.description == description &&
        other.trailingText == trailingText &&
        other.isAi == isAi &&
        other.appendSpace == appendSpace &&
        other.priority == priority;
  }

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        label,
        insertText,
        replacementRange,
        description,
        trailingText,
        isAi,
        appendSpace,
        priority,
      );
}
