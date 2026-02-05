// @telos L1:function:lib/features/terminal/presentation/widgets:block_widget

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/block_colors.dart';
import '../../domain/entities/block.dart';
import '../../domain/entities/block_status.dart';
import '../providers/block_provider.dart';

/// Displays a single terminal block with command, output, and status.
///
/// A block consists of:
/// - Header: command text, status icon, timestamp, collapse toggle
/// - Content: ANSI-rendered output (collapsible)
/// - Left border: colored by status
class BlockWidget extends ConsumerWidget {
  const BlockWidget({
    super.key,
    required this.block,
    this.onCopyCommand,
    this.onCopyOutput,
    this.onRerun,
  });

  /// The terminal block to display.
  final TerminalBlock block;

  /// Callback when user copies the command.
  final VoidCallback? onCopyCommand;

  /// Callback when user copies the output.
  final VoidCallback? onCopyOutput;

  /// Callback when user wants to re-run the command.
  final VoidCallback? onRerun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final statusColor = BlockColors.forStatus(block.status, brightness);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: BlockColors.statusBorderWidth,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BlockHeader(
              block: block,
              statusColor: statusColor,
              onToggle: () => _toggleCollapse(ref),
              onCopyCommand: onCopyCommand ?? () => _copyCommand(context),
            ),
            // TUI session blocks show TUI indicator instead of output
            if (!block.isCollapsed)
              block.isTuiSession
                  ? _TuiSessionContent(block: block)
                  : _BlockContent(block: block),
          ],
        ),
      ),
    );
  }

  void _toggleCollapse(WidgetRef ref) {
    ref.read(blockListControllerProvider.notifier).toggleCollapsed(block.id);
  }

  void _copyCommand(BuildContext context) {
    Clipboard.setData(ClipboardData(text: block.command));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Command copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// Header section of a block showing command and status.
class _BlockHeader extends StatelessWidget {
  const _BlockHeader({
    required this.block,
    required this.statusColor,
    required this.onToggle,
    required this.onCopyCommand,
  });

  final TerminalBlock block;
  final Color statusColor;
  final VoidCallback onToggle;
  final VoidCallback onCopyCommand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onToggle,
      onLongPress: onCopyCommand,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Collapse/expand icon
            Icon(
              block.isCollapsed
                  ? Icons.chevron_right
                  : Icons.keyboard_arrow_down,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),

            // Status icon (with animation for running)
            _StatusIcon(
              status: block.status,
              color: statusColor,
            ),
            const SizedBox(width: 8),

            // TUI session indicator badge
            if (block.isTuiSession) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.deepPurple.shade800.withValues(alpha: 0.6)
                      : Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fullscreen,
                      size: 12,
                      color: isDark
                          ? Colors.deepPurple.shade200
                          : Colors.deepPurple.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TUI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.deepPurple.shade200
                            : Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Command text
            Expanded(
              child: Text(
                block.command,
                style: TextStyle(
                  fontFamily: 'JetBrainsMonoNF',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Timestamp
            Text(
              _formatTime(block.startedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Duration (if completed)
            if (block.executionDuration != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatDuration(block.executionDuration!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.Hms().format(time);
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes >= 1) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else if (duration.inSeconds >= 1) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMilliseconds}ms';
    }
  }
}

/// Animated status icon that pulses when running.
class _StatusIcon extends StatefulWidget {
  const _StatusIcon({
    required this.status,
    required this.color,
  });

  final BlockStatus status;
  final Color color;

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.status == BlockStatus.running) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == BlockStatus.running &&
        oldWidget.status != BlockStatus.running) {
      _controller.repeat(reverse: true);
    } else if (widget.status != BlockStatus.running &&
        oldWidget.status == BlockStatus.running) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = BlockColors.iconForStatus(widget.status);

    if (widget.status == BlockStatus.running) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Icon(icon, size: 18, color: widget.color),
          );
        },
      );
    }

    return Icon(icon, size: 18, color: widget.color);
  }
}

/// Content section for TUI session blocks.
///
/// TUI sessions don't capture output (they use the alternate screen buffer),
/// so we show a distinct indicator with session metadata instead.
class _TuiSessionContent extends StatelessWidget {
  const _TuiSessionContent({required this.block});

  final TerminalBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.deepPurple.shade900.withValues(alpha: 0.3)
            : Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? Colors.deepPurple.shade700.withValues(alpha: 0.5)
              : Colors.deepPurple.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // TUI mode icon
          Icon(
            Icons.fullscreen,
            size: 24,
            color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple,
          ),
          const SizedBox(width: 12),

          // TUI session info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TUI Session',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMonoNF',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.deepPurple.shade200
                        : Colors.deepPurple.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSessionInfo(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Status indicator for running TUI
          if (block.isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.blue.shade200 : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.blue.shade200 : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _buildSessionInfo() {
    final parts = <String>[];

    // App name hint based on command
    final command = block.command.toLowerCase();
    if (command.contains('vim') || command.contains('nvim')) {
      parts.add('Vim editor');
    } else if (command.contains('htop') || command.contains('top')) {
      parts.add('Process monitor');
    } else if (command.contains('less') || command.contains('more')) {
      parts.add('Pager');
    } else if (command.contains('nano')) {
      parts.add('Nano editor');
    } else if (command.contains('man')) {
      parts.add('Manual page');
    } else if (command.contains('claude')) {
      parts.add('Claude Code');
    } else {
      parts.add('Full-screen application');
    }

    // Duration info
    if (block.executionDuration != null) {
      parts.add('ran for ${_formatDuration(block.executionDuration!)}');
    } else if (block.isRunning) {
      final elapsed = DateTime.now().difference(block.startedAt);
      parts.add('running for ${_formatDuration(elapsed)}');
    }

    return parts.join(' - ');
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours >= 1) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else if (duration.inSeconds >= 1) {
      return '${duration.inSeconds}s';
    } else {
      return '< 1s';
    }
  }
}

/// Content section showing command output.
class _BlockContent extends StatelessWidget {
  const _BlockContent({required this.block});

  final TerminalBlock block;

  /// Regex to match ANSI escape sequences.
  static final _ansiEscapeRegex = RegExp(
    r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])',
  );

  /// Strips ANSI escape codes from text for display.
  String _stripAnsiCodes(String text) {
    return text.replaceAll(_ansiEscapeRegex, '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (block.output.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Text(
          block.isRunning ? 'Running...' : '(no output)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Strip ANSI codes for clean text display
    final cleanOutput = _stripAnsiCodes(block.output);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            cleanOutput,
            style: TextStyle(
              fontFamily: 'JetBrainsMonoNF',
              fontSize: 12,
              height: 1.3,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
