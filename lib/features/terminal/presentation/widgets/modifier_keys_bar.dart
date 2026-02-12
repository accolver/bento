// @telos L1:function:lib/features/terminal/presentation/widgets:modifier_keys_bar

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A bar of special keys for terminal input.
///
/// Mobile soft keyboards don't have these keys, so we provide virtual
/// buttons: Esc, Ctrl+C, Ctrl+D, Tab, arrow keys, and more.
///
/// Supports compact (1-row) and expanded (2-row) modes. The compact row
/// has the most essential keys; the expanded row adds navigation and
/// additional Ctrl combos.
class ModifierKeysBar extends StatefulWidget {
  const ModifierKeysBar({
    super.key,
    required this.onKey,
  });

  /// Called when a key is pressed (Esc, Tab, arrows, Ctrl combos, etc.).
  final void Function(String key) onKey;

  @override
  State<ModifierKeysBar> createState() => _ModifierKeysBarState();
}

class _ModifierKeysBarState extends State<ModifierKeysBar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    HapticFeedback.selectionClick();
  }

  void _sendKey(String key) {
    widget.onKey(key);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary row: most essential keys
          SizedBox(
            height: 44,
            child: Row(
              children: [
                // Toggle expand/collapse button
                _buildToggleButton(colorScheme),

                // Esc key
                _buildKey(
                  label: 'Esc',
                  onTap: () => _sendKey('\x1b'),
                ),

                // Ctrl+C - interrupt
                _buildKey(
                  label: '^C',
                  onTap: () => _sendKey('\x03'),
                ),

                // Ctrl+D - EOF / exit
                _buildKey(
                  label: '^D',
                  onTap: () => _sendKey('\x04'),
                ),

                // Tab key
                _buildKey(
                  label: 'Tab',
                  onTap: () => _sendKey('\t'),
                ),

                const Spacer(),

                // Arrow keys
                _buildKey(
                  icon: Icons.keyboard_arrow_left,
                  onTap: () => _sendKey('\x1b[D'),
                ),
                _buildKey(
                  icon: Icons.keyboard_arrow_right,
                  onTap: () => _sendKey('\x1b[C'),
                ),
                _buildKey(
                  icon: Icons.keyboard_arrow_up,
                  onTap: () => _sendKey('\x1b[A'),
                ),
                _buildKey(
                  icon: Icons.keyboard_arrow_down,
                  onTap: () => _sendKey('\x1b[B'),
                ),
              ],
            ),
          ),

          // Expanded row: additional keys (animated)
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  // Ctrl+Z - suspend
                  _buildKey(
                    label: '^Z',
                    onTap: () => _sendKey('\x1a'),
                  ),

                  // Ctrl+L - clear screen
                  _buildKey(
                    label: '^L',
                    onTap: () => _sendKey('\x0c'),
                  ),

                  // Ctrl+A - beginning of line
                  _buildKey(
                    label: '^A',
                    onTap: () => _sendKey('\x01'),
                  ),

                  // Ctrl+E - end of line
                  _buildKey(
                    label: '^E',
                    onTap: () => _sendKey('\x05'),
                  ),

                  const Spacer(),

                  // Home key
                  _buildKey(
                    label: 'Home',
                    onTap: () => _sendKey('\x1b[H'),
                  ),

                  // End key
                  _buildKey(
                    label: 'End',
                    onTap: () => _sendKey('\x1b[F'),
                  ),

                  // Page Up
                  _buildKey(
                    label: 'PgUp',
                    onTap: () => _sendKey('\x1b[5~'),
                  ),

                  // Page Down
                  _buildKey(
                    label: 'PgDn',
                    onTap: () => _sendKey('\x1b[6~'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        child: Container(
          width: 36,
          height: 44,
          alignment: Alignment.center,
          child: AnimatedRotation(
            turns: _expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.expand_less,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
