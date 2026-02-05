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
            if (!block.isCollapsed) _BlockContent(block: block),
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
