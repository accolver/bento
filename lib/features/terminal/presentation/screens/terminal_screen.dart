// @telos L1:function:lib/features/terminal/presentation/screens:terminal_screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/terminal_colors.dart';
import '../../domain/entities/terminal_config.dart';
import '../providers/terminal_provider.dart';
import '../widgets/modifier_keys_bar.dart';
import '../widgets/terminal_view.dart';

/// Full-screen terminal display with modifier key bar.
///
/// This screen provides a complete terminal interface including:
/// - Terminal view (main content)
/// - Modifier keys bar (Ctrl, Alt, Esc, arrows)
/// - Proper keyboard handling
class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({
    super.key,
    this.title,
  });

  /// Optional title for the terminal (e.g., connection name).
  final String? title;

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  bool _ctrlActive = false;
  bool _altActive = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = TerminalColors.forBrightness(brightness);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              backgroundColor: colors.background,
              foregroundColor: colors.foreground,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Terminal view (expandable)
            Expanded(
              child: BentoTerminalView(
                onResize: _handleResize,
              ),
            ),

            // Modifier keys bar
            ModifierKeysBar(
              onKey: _handleKey,
              onCtrlToggle: (active) => _ctrlActive = active,
              onAltToggle: (active) => _altActive = active,
            ),
          ],
        ),
      ),
    );
  }

  void _handleResize(TerminalDimensions dimensions) {
    // Could log or update UI with dimensions
    debugPrint(
      'Terminal resized: ${dimensions.columns}x${dimensions.rows}',
    );
  }

  void _handleKey(String key) {
    final controller = ref.read(terminalControllerProvider.notifier);

    // Apply modifiers if active
    if (_ctrlActive && key.length == 1) {
      // Convert to control character (e.g., 'c' -> Ctrl+C = 0x03)
      final char = key.codeUnitAt(0);
      if (char >= 0x61 && char <= 0x7A) {
        // a-z
        controller.write(String.fromCharCode(char - 0x60));
      } else if (char >= 0x41 && char <= 0x5A) {
        // A-Z
        controller.write(String.fromCharCode(char - 0x40));
      }
    } else if (_altActive && key.length == 1) {
      // Send Alt as Escape prefix
      controller.write('\x1b$key');
    } else {
      controller.write(key);
    }

    // Reset modifiers after use (one-shot mode)
    setState(() {
      _ctrlActive = false;
      _altActive = false;
    });
  }
}
