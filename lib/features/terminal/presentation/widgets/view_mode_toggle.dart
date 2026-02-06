// @telos L1:function:lib/features/terminal/presentation/widgets:view_mode_toggle

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/view_mode.dart';
import '../providers/view_mode_provider.dart';

/// A segmented button for toggling between view modes.
///
/// Shows three options: Split, Terminal, Blocks.
/// The current selection is highlighted.
class ViewModeToggle extends ConsumerWidget {
  const ViewModeToggle({
    super.key,
    this.compact = false,
  });

  /// If true, shows only icons without labels.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(viewModeControllerProvider);

    return SegmentedButton<ViewMode>(
      segments: [
        ButtonSegment<ViewMode>(
          value: ViewMode.split,
          icon: const Icon(Icons.vertical_split, size: 18),
          label: compact ? null : const Text('Split'),
          tooltip: ViewMode.split.description,
        ),
        ButtonSegment<ViewMode>(
          value: ViewMode.fullTerminal,
          icon: const Icon(Icons.terminal, size: 18),
          label: compact ? null : const Text('Term'),
          tooltip: ViewMode.fullTerminal.description,
        ),
        ButtonSegment<ViewMode>(
          value: ViewMode.fullBlocks,
          icon: const Icon(Icons.view_agenda, size: 18),
          label: compact ? null : const Text('Blocks'),
          tooltip: ViewMode.fullBlocks.description,
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (Set<ViewMode> selection) {
        ref.read(viewModeControllerProvider.notifier).setViewMode(
              selection.first,
            );
      },
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: 4,
          ),
        ),
      ),
    );
  }
}

/// A compact icon button that cycles through view modes.
///
/// Shows the icon for the current mode. Tapping cycles to the next mode.
/// Long-press shows a popup menu to select any mode directly.
class ViewModeCycleButton extends ConsumerWidget {
  const ViewModeCycleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(viewModeControllerProvider);

    return PopupMenuButton<ViewMode>(
      icon: Icon(_getIconForMode(currentMode)),
      tooltip: 'View mode: ${currentMode.label}',
      onSelected: (mode) {
        ref.read(viewModeControllerProvider.notifier).setViewMode(mode);
      },
      itemBuilder: (context) => ViewMode.values.map((mode) {
        return PopupMenuItem<ViewMode>(
          value: mode,
          child: Row(
            children: [
              Icon(
                _getIconForMode(mode),
                size: 20,
                color: mode == currentMode
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mode.label,
                      style: TextStyle(
                        fontWeight: mode == currentMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      mode.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              if (mode == currentMode)
                Icon(
                  Icons.check,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForMode(ViewMode mode) {
    switch (mode) {
      case ViewMode.split:
        return Icons.vertical_split;
      case ViewMode.fullTerminal:
        return Icons.terminal;
      case ViewMode.fullBlocks:
        return Icons.view_agenda;
    }
  }
}
