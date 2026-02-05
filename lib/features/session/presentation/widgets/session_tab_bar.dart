// @telos L2:contract:component-tab-bar

import 'package:flutter/material.dart';

import '../../domain/entities/session.dart';
import '../../domain/entities/session_status.dart';

/// A horizontal tab bar for displaying and managing terminal sessions.
///
/// Shows session tabs with status indicators, unread badges, and close buttons.
/// Supports scrolling when there are many tabs.
class SessionTabBar extends StatelessWidget {
  const SessionTabBar({
    required this.sessions,
    required this.activeSessionId,
    required this.onTabSelected,
    required this.onAddTap,
    this.onTabClose,
    this.onTabLongPress,
    this.onReorder,
    super.key,
  });

  /// List of all sessions to display as tabs.
  final List<Session> sessions;

  /// ID of the currently active session.
  final String? activeSessionId;

  /// Called when a tab is tapped.
  final void Function(String sessionId) onTabSelected;

  /// Called when the add button is tapped.
  final VoidCallback onAddTap;

  /// Called when a tab's close button is tapped.
  final void Function(String sessionId)? onTabClose;

  /// Called when a tab is long-pressed.
  final void Function(String sessionId)? onTabLongPress;

  /// Called when tabs are reordered via drag.
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: sessions.map((session) {
                final isActive = session.id == activeSessionId;
                return _SessionTab(
                  session: session,
                  isActive: isActive,
                  onTap: () => onTabSelected(session.id),
                  onClose:
                      onTabClose != null ? () => onTabClose!(session.id) : null,
                  onLongPress: onTabLongPress != null
                      ? () => onTabLongPress!(session.id)
                      : null,
                );
              }).toList(),
            ),
          ),
        ),
        _AddButton(onTap: onAddTap),
      ],
    );
  }
}

/// Individual session tab widget.
class _SessionTab extends StatelessWidget {
  const _SessionTab({
    required this.session,
    required this.isActive,
    required this.onTap,
    this.onClose,
    this.onLongPress,
  });

  final Session session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClose;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Material(
        color: isActive ? Colors.grey[800] : Colors.grey[900],
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 80,
              maxWidth: 160,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusIndicator(status: session.status),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    session.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? Colors.white : Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (session.unreadCount > 0 && !isActive) ...[
                  const SizedBox(width: 4),
                  _UnreadBadge(count: session.unreadCount),
                ],
                if (onClose != null) ...[
                  const SizedBox(width: 4),
                  _CloseButton(onTap: onClose!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status indicator dot.
class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final SessionStatus status;

  Color get _color {
    switch (status) {
      case SessionStatus.connected:
        return Colors.green;
      case SessionStatus.connecting:
      case SessionStatus.reconnecting:
        return Colors.orange;
      case SessionStatus.disconnected:
      case SessionStatus.failed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Unread count badge.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  String get _displayCount => count > 99 ? '99+' : count.toString();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _displayCount,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colorScheme.onError,
        ),
      ),
    );
  }
}

/// Close button for tab.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const Icon(
        Icons.close,
        size: 16,
        color: Colors.white54,
      ),
    );
  }
}

/// Add session button.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.add),
        iconSize: 20,
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
