// @telos L1:function:lib/features/terminal/presentation/widgets:modifier_keys_bar

import 'package:flutter/material.dart';

/// A bar of special keys for terminal input.
///
/// Mobile soft keyboards don't have these keys, so we provide virtual
/// buttons: Esc, Ctrl+C, Tab, and arrow keys.
class ModifierKeysBar extends StatelessWidget {
  const ModifierKeysBar({
    super.key,
    required this.onKey,
  });

  /// Called when a key is pressed (Esc, Tab, arrows, Ctrl+C).
  final void Function(String key) onKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          // Esc key
          _buildKey(
            label: 'Esc',
            onTap: () => onKey('\x1b'),
          ),

          // Ctrl+C - essential for interrupting commands in TUI apps
          _buildKey(
            label: '^C',
            onTap: () => onKey('\x03'), // ETX - Ctrl+C
          ),

          // Tab key
          _buildKey(
            label: 'Tab',
            onTap: () => onKey('\t'),
          ),

          const Spacer(),

          // Arrow keys
          _buildKey(
            icon: Icons.keyboard_arrow_up,
            onTap: () => onKey('\x1b[A'),
          ),
          _buildKey(
            icon: Icons.keyboard_arrow_down,
            onTap: () => onKey('\x1b[B'),
          ),
          _buildKey(
            icon: Icons.keyboard_arrow_left,
            onTap: () => onKey('\x1b[D'),
          ),
          _buildKey(
            icon: Icons.keyboard_arrow_right,
            onTap: () => onKey('\x1b[C'),
          ),
        ],
      ),
    );
  }

  Widget _buildKey({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 44,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 20)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
