// @telos L1:function:lib/features/terminal/presentation/widgets:modifier_keys_bar

import 'package:flutter/material.dart';

/// A bar of modifier keys (Ctrl, Alt, Esc, Tab) for terminal input.
///
/// Mobile soft keyboards don't have these keys, so we provide virtual
/// buttons that can be toggled or tapped.
class ModifierKeysBar extends StatefulWidget {
  const ModifierKeysBar({
    super.key,
    required this.onKey,
    this.onCtrlToggle,
    this.onAltToggle,
  });

  /// Called when a key is pressed (Esc, Tab, arrows).
  final void Function(String key) onKey;

  /// Called when Ctrl modifier state changes.
  final void Function(bool active)? onCtrlToggle;

  /// Called when Alt modifier state changes.
  final void Function(bool active)? onAltToggle;

  @override
  State<ModifierKeysBar> createState() => _ModifierKeysBarState();
}

class _ModifierKeysBarState extends State<ModifierKeysBar> {
  bool _ctrlActive = false;
  bool _altActive = false;

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
            onTap: () => widget.onKey('\x1b'),
          ),

          // Ctrl modifier (toggle)
          _buildToggleKey(
            label: 'Ctrl',
            active: _ctrlActive,
            onTap: () {
              setState(() => _ctrlActive = !_ctrlActive);
              widget.onCtrlToggle?.call(_ctrlActive);
            },
          ),

          // Alt modifier (toggle)
          _buildToggleKey(
            label: 'Alt',
            active: _altActive,
            onTap: () {
              setState(() => _altActive = !_altActive);
              widget.onAltToggle?.call(_altActive);
            },
          ),

          // Tab key
          _buildKey(
            label: 'Tab',
            onTap: () => widget.onKey('\t'),
          ),

          const Spacer(),

          // Arrow keys
          _buildKey(
            icon: Icons.keyboard_arrow_up,
            onTap: () => widget.onKey('\x1b[A'),
          ),
          _buildKey(
            icon: Icons.keyboard_arrow_down,
            onTap: () => widget.onKey('\x1b[B'),
          ),
          _buildKey(
            icon: Icons.keyboard_arrow_left,
            onTap: () => widget.onKey('\x1b[D'),
          ),
          _buildKey(
            icon: Icons.keyboard_arrow_right,
            onTap: () => widget.onKey('\x1b[C'),
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
          width: 48,
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

  Widget _buildToggleKey({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          alignment: Alignment.center,
          decoration: active
              ? BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? colorScheme.onPrimaryContainer : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Reset modifier states (call after key press if using one-shot mode).
  void resetModifiers() {
    if (_ctrlActive || _altActive) {
      setState(() {
        _ctrlActive = false;
        _altActive = false;
      });
      widget.onCtrlToggle?.call(false);
      widget.onAltToggle?.call(false);
    }
  }
}
