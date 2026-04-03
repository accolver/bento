// @telos L2:contract:component-command-ribbon

import 'package:flutter/material.dart';

import '../../domain/entities/command_suggestion_chip.dart';
import '../../domain/entities/prompt_input_state.dart';

/// A horizontal scrollable strip showing command suggestions.
class CommandRibbon extends StatelessWidget {
  const CommandRibbon({
    required this.sessionId,
    required this.inputState,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onSymbolToggle,
    this.onAiRequested,
    super.key,
  });

  final String sessionId;
  final PromptInputState inputState;
  final List<CommandSuggestionChip> suggestions;
  final void Function(CommandSuggestionChip suggestion) onSuggestionTap;
  final VoidCallback onSymbolToggle;
  final VoidCallback? onAiRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!inputState.canShowRibbon || inputState.isInTuiMode) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _ActionButton(
            label: '#',
            tooltip: 'Symbols',
            onTap: onSymbolToggle,
          ),
          _ActionButton(
            icon: Icons.auto_awesome,
            tooltip: 'Ask AI',
            onTap: onAiRequested,
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(
            child: suggestions.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return _SuggestionChip(
                        suggestion: suggestion,
                        onTap: () {
                          if (suggestion.kind == CommandSuggestionKind.ai) {
                            onAiRequested?.call();
                          } else {
                            onSuggestionTap(suggestion);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    this.label,
    this.icon,
    required this.tooltip,
    this.onTap,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant)
                  : Text(
                      label!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  final CommandSuggestionChip suggestion;
  final VoidCallback onTap;

  IconData? get _icon {
    switch (suggestion.kind) {
      case CommandSuggestionKind.history:
        return Icons.history;
      case CommandSuggestionKind.ai:
        return Icons.auto_awesome;
      case CommandSuggestionKind.command:
      case CommandSuggestionKind.subcommand:
      case CommandSuggestionKind.argument:
      case CommandSuggestionKind.file:
      case CommandSuggestionKind.snippet:
      case CommandSuggestionKind.symbol:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSymbol = suggestion.kind == CommandSuggestionKind.symbol;
    final isAi = suggestion.kind == CommandSuggestionKind.ai;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Material(
        color: isAi
            ? theme.colorScheme.primaryContainer
            : isSymbol
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              minWidth: isSymbol ? 36 : 48,
              maxWidth: 220,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isSymbol ? 8 : 10,
              vertical: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_icon != null) ...[
                  Icon(_icon, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    suggestion.label,
                    style: TextStyle(
                      fontSize: isSymbol ? 16 : 13,
                      fontFamily: isSymbol ? 'JetBrainsMono' : null,
                      fontWeight: isSymbol || isAi
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isAi
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
