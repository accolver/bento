// @telos L2:contract:component-command-ribbon

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/command_ribbon_provider.dart';

/// A horizontal scrollable strip showing command suggestions.
///
/// Positioned above the keyboard, the ribbon provides:
/// - **Idle mode** — recent history or common-command defaults.
/// - **Completing mode** — context-aware subcommand / history completions.
/// - **Symbol mode** — quick-access shell symbols (pipe, redirect, etc.).
///
/// The `#` toggle on the leading edge switches between symbol mode and the
/// previous suggestion context.
class CommandRibbon extends ConsumerWidget {
  const CommandRibbon({
    required this.sessionId,
    required this.onSuggestionTap,
    this.onSymbolToggle,
    super.key,
  });

  /// Session ID used to key the [CommandRibbonController].
  final String sessionId;

  /// Called when a suggestion chip is tapped.
  ///
  /// The [text] parameter is the value to insert into the input field
  /// (which may include a trailing space for commands that expect arguments).
  final void Function(String text) onSuggestionTap;

  /// Optional callback fired when the symbol toggle is pressed.
  final VoidCallback? onSymbolToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ribbonState = ref.watch(commandRibbonControllerProvider(sessionId));
    final theme = Theme.of(context);
    final isSymbolMode = ribbonState.mode == RibbonMode.symbols;

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
          // Symbol toggle button
          _SymbolToggleButton(
            isActive: isSymbolMode,
            onTap: () {
              final controller = ref.read(
                commandRibbonControllerProvider(sessionId).notifier,
              );
              if (isSymbolMode) {
                controller.hideSymbols();
              } else {
                controller.showSymbols();
              }
              onSymbolToggle?.call();
            },
          ),

          // Vertical divider
          Container(
            width: 1,
            height: 24,
            color: theme.colorScheme.outlineVariant,
          ),

          // Horizontally-scrollable suggestion chips
          Expanded(
            child: ribbonState.suggestions.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: ribbonState.suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = ribbonState.suggestions[index];
                      return _SuggestionChip(
                        suggestion: suggestion,
                        onTap: () => onSuggestionTap(
                          suggestion.insertText ?? suggestion.text,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Private widgets
// -----------------------------------------------------------------------------

/// The `#` button on the leading edge that toggles symbol mode.
class _SymbolToggleButton extends StatelessWidget {
  const _SymbolToggleButton({
    required this.isActive,
    required this.onTap,
  });

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isActive ? theme.colorScheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An individual suggestion chip inside the ribbon.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  final RibbonSuggestion suggestion;
  final VoidCallback onTap;

  /// Leading icon for history suggestions; other types have no icon.
  IconData? get _icon {
    switch (suggestion.type) {
      case RibbonSuggestionType.history:
        return Icons.history;
      case RibbonSuggestionType.subcommand:
      case RibbonSuggestionType.symbol:
      case RibbonSuggestionType.common:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSymbol = suggestion.type == RibbonSuggestionType.symbol;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Material(
        color: isSymbol
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              minWidth: isSymbol ? 36 : 48,
              maxWidth: 200,
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
                    suggestion.text,
                    style: TextStyle(
                      fontSize: isSymbol ? 16 : 13,
                      fontFamily: isSymbol ? 'JetBrainsMono' : null,
                      fontWeight: isSymbol ? FontWeight.bold : FontWeight.w500,
                      color: theme.colorScheme.onSurface,
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
