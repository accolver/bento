// @telos L1:function:lib/features/terminal/presentation/widgets:block_widget

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/block_colors.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../data/services/ansi_stripper.dart';
import '../../domain/entities/block.dart';
import '../../domain/entities/block_status.dart';
import '../providers/block_provider.dart';

/// Displays a single terminal block with command, output, and status.
///
/// A block consists of:
/// - Header: command text, status icon, timestamp, collapse toggle
/// - Content: ANSI-rendered output (collapsible)
/// - Action bar: copy, re-run buttons (when expanded)
/// - Left border: colored by status
class BlockWidget extends ConsumerWidget {
  const BlockWidget({
    super.key,
    required this.block,
    this.onRerun,
  });

  /// The terminal block to display.
  final TerminalBlock block;

  /// Callback when user wants to re-run the command.
  final void Function(String command)? onRerun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final statusColor = BlockColors.forStatus(block.status, brightness);

    return GestureDetector(
      onLongPress: () => _showContextMenu(context, ref),
      child: Card(
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
                onCopyCommand: () => _copyCommand(context),
              ),
              // TUI session blocks show TUI indicator instead of output
              if (!block.isCollapsed)
                block.isTuiSession
                    ? _TuiSessionContent(block: block)
                    : _BlockContent(
                        block: block,
                        onCopyOutput: () => _copyOutput(context),
                        onCopyAll: () => _copyAll(context),
                        onRerun: () => _rerunCommand(context),
                        onLoadFullOutput: () => _loadFullOutput(ref),
                      ),
            ],
          ),
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

  void _copyOutput(BuildContext context) {
    final cleanOutput = AnsiStripper.strip(block.output);
    Clipboard.setData(ClipboardData(text: cleanOutput));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Output copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _copyAll(BuildContext context) {
    final cleanOutput = AnsiStripper.strip(block.output);
    final formatted = '\$ ${block.command}\n$cleanOutput';
    Clipboard.setData(ClipboardData(text: formatted));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _rerunCommand(BuildContext context) {
    if (onRerun != null) {
      onRerun!(block.command);
    }
  }

  void _loadFullOutput(WidgetRef ref) {
    ref.read(blockListControllerProvider.notifier).loadFullOutput(block.id);
  }

  /// Shows a context menu with all available actions.
  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width / 2,
        offset.dy + size.height / 2,
        offset.dx + size.width / 2,
        offset.dy + size.height / 2,
      ),
      items: [
        const PopupMenuItem(
          value: 'copy_command',
          child: Row(
            children: [
              Icon(Icons.terminal, size: 18),
              SizedBox(width: 12),
              Text('Copy Command'),
            ],
          ),
        ),
        if (block.output.isNotEmpty) ...[
          const PopupMenuItem(
            value: 'copy_output',
            child: Row(
              children: [
                Icon(Icons.content_copy, size: 18),
                SizedBox(width: 12),
                Text('Copy Output'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'copy_all',
            child: Row(
              children: [
                Icon(Icons.copy_all, size: 18),
                SizedBox(width: 12),
                Text('Copy All'),
              ],
            ),
          ),
        ],
        if (block.isCompleted && onRerun != null)
          const PopupMenuItem(
            value: 'rerun',
            child: Row(
              children: [
                Icon(Icons.replay, size: 18),
                SizedBox(width: 12),
                Text('Re-run Command'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'toggle_collapse',
          child: Row(
            children: [
              Icon(
                block.isCollapsed ? Icons.expand_more : Icons.expand_less,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(block.isCollapsed ? 'Expand' : 'Collapse'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (!context.mounted) return;

      switch (value) {
        case 'copy_command':
          _copyCommand(context);
        case 'copy_output':
          _copyOutput(context);
        case 'copy_all':
          _copyAll(context);
        case 'rerun':
          _rerunCommand(context);
        case 'toggle_collapse':
          _toggleCollapse(ref);
      }
    });
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
                  // Fallback for emoji which are in different Unicode blocks
                  fontFamilyFallback: const ['Noto Color Emoji'],
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
                    // Fallback for emoji which are in different Unicode blocks
                    fontFamilyFallback: const ['Noto Color Emoji'],
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

/// Content section showing command output with action bar.
class _BlockContent extends ConsumerStatefulWidget {
  const _BlockContent({
    required this.block,
    this.onCopyOutput,
    this.onCopyAll,
    this.onRerun,
    this.onLoadFullOutput,
  });

  final TerminalBlock block;
  final VoidCallback? onCopyOutput;
  final VoidCallback? onCopyAll;
  final VoidCallback? onRerun;
  final VoidCallback? onLoadFullOutput;

  @override
  ConsumerState<_BlockContent> createState() => _BlockContentState();
}

class _BlockContentState extends ConsumerState<_BlockContent> {
  String? _summary;
  bool _isLoadingSummary = false;
  String? _summaryError;

  Future<void> _generateSummary() async {
    if (_isLoadingSummary) return;

    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final cleanOutput = AnsiStripper.strip(widget.block.output);
      final summary = await aiService.summarizeOutput(
        widget.block.command,
        cleanOutput,
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryError = e.toString().contains('not configured')
              ? 'Set up AI in settings to use summaries'
              : 'Failed to generate summary';
          _isLoadingSummary = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final block = widget.block;

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
    final cleanOutput = AnsiStripper.strip(block.output);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Output content
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
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
                  // Fallback for emoji which are in different Unicode blocks
                  fontFamilyFallback: const ['Noto Color Emoji'],
                  fontSize: 12,
                  height: 1.3,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ),
          // Truncation indicator with "Load Full Output" button
          if (block.isTruncated)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: InkWell(
                onTap: widget.onLoadFullOutput,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange.shade900.withValues(alpha: 0.3)
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark
                          ? Colors.orange.shade700.withValues(alpha: 0.5)
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.unfold_more,
                        size: 16,
                        color: isDark
                            ? Colors.orange.shade200
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Load Full Output',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.orange.shade200
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // AI Summary section (when available)
          if (_summary != null || _isLoadingSummary || _summaryError != null)
            _AiSummarySection(
              summary: _summary,
              isLoading: _isLoadingSummary,
              error: _summaryError,
            ),
          // Action bar (only for completed blocks)
          if (block.isCompleted)
            _BlockActionBar(
              onCopyOutput: widget.onCopyOutput,
              onCopyAll: widget.onCopyAll,
              onRerun: widget.onRerun,
              onSummarize: _summary == null ? _generateSummary : null,
              isLoadingSummary: _isLoadingSummary,
            ),
        ],
      ),
    );
  }
}

/// Displays the AI-generated summary of command output.
class _AiSummarySection extends StatelessWidget {
  const _AiSummarySection({
    this.summary,
    this.isLoading = false,
    this.error,
  });

  final String? summary;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isLoading
                ? Icons.hourglass_empty
                : error != null
                    ? Icons.error_outline
                    : Icons.auto_awesome,
            size: 16,
            color: error != null
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isLoading
                ? Text(
                    'Generating summary...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : error != null
                    ? Text(
                        error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      )
                    : Text(
                        summary ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Action bar with copy, summarize, and re-run buttons.
class _BlockActionBar extends StatelessWidget {
  const _BlockActionBar({
    this.onCopyOutput,
    this.onCopyAll,
    this.onRerun,
    this.onSummarize,
    this.isLoadingSummary = false,
  });

  final VoidCallback? onCopyOutput;
  final VoidCallback? onCopyAll;
  final VoidCallback? onRerun;
  final VoidCallback? onSummarize;
  final bool isLoadingSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _ActionButton(
            icon: Icons.content_copy,
            label: 'Output',
            onPressed: onCopyOutput,
            tooltip: 'Copy output to clipboard',
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.copy_all,
            label: 'All',
            onPressed: onCopyAll,
            tooltip: 'Copy command and output',
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: isLoadingSummary ? Icons.hourglass_empty : Icons.auto_awesome,
            label: 'Summarize',
            onPressed: isLoadingSummary ? null : onSummarize,
            tooltip: onSummarize != null
                ? 'Generate AI summary'
                : 'Summary generated',
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.replay,
            label: 'Re-run',
            onPressed: onRerun,
            tooltip: 'Re-run this command',
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

/// Individual action button in the action bar.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.onSurfaceVariant;

    final button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: buttonColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: buttonColor,
              ),
            ),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
