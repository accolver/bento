// @telos L1:function:lib/features/terminal/presentation/screens:terminal_screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/terminal_colors.dart';
import '../../domain/entities/terminal_config.dart';
import '../providers/block_provider.dart';
import '../providers/output_router_provider.dart';
import '../providers/terminal_config_provider.dart';
import '../providers/terminal_provider.dart';
import '../widgets/block_list_view.dart';
import '../widgets/modifier_keys_bar.dart';
import '../widgets/terminal_view.dart';

/// Full-screen terminal display with modifier key bar.
///
/// This screen provides a complete terminal interface including:
/// - Terminal view (main content) - classic mode
/// - Block list view (semantic blocks) - when enabled
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
  void initState() {
    super.initState();
    // Initialize blocks for this session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBlocks();
    });
  }

  void _initializeBlocks() {
    print('[TerminalScreen] _initializeBlocks called');
    final config = ref.read(terminalConfigProvider);
    print(
        '[TerminalScreen] enableSemanticBlocks: ${config.enableSemanticBlocks}');
    if (config.enableSemanticBlocks) {
      // Load any existing blocks for this session
      ref.read(blockListControllerProvider.notifier).loadBlocks();
      print('[TerminalScreen] Loaded blocks');

      // Force initialization of the output router if it hasn't been created yet
      // The router sets up its terminal callback in build(), so we just need to access it
      ref.read(outputRouterControllerProvider);
      print('[TerminalScreen] OutputRouter initialized');

      // Set up callback to dismiss keyboard when command is submitted
      ref
          .read(outputRouterControllerProvider.notifier)
          .setCommandSubmittedCallback(() {
        // Dismiss the keyboard
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = TerminalColors.forBrightness(brightness);
    final config = ref.watch(terminalConfigProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(colors, config),
      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: config.enableSemanticBlocks
                  ? _buildSemanticBlocksView()
                  : _buildClassicTerminalView(),
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

  PreferredSizeWidget _buildAppBar(
    TerminalColorScheme colors,
    TerminalConfig config,
  ) {
    return AppBar(
      title: Text(widget.title ?? 'Terminal'),
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _handleDisconnect,
      ),
      actions: [
        // Connection status indicator
        _ConnectionStatusIndicator(),
        // Toggle between semantic blocks and classic view
        IconButton(
          icon: Icon(
            config.enableSemanticBlocks ? Icons.view_agenda : Icons.terminal,
          ),
          tooltip: config.enableSemanticBlocks
              ? 'Switch to classic view'
              : 'Switch to block view',
          onPressed: _toggleViewMode,
        ),
        // Collapse/expand all (only in semantic blocks mode)
        if (config.enableSemanticBlocks)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'collapse_all',
                child: Text('Collapse All'),
              ),
              const PopupMenuItem(
                value: 'expand_all',
                child: Text('Expand All'),
              ),
              const PopupMenuItem(
                value: 'clear_blocks',
                child: Text('Clear Blocks'),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _handleDisconnect() async {
    // Disconnect SSH and go back to previous screen
    await ref.read(terminalControllerProvider.notifier).disconnectSSH();

    // Reset output router if semantic blocks enabled
    final config = ref.read(terminalConfigProvider);
    if (config.enableSemanticBlocks) {
      ref.read(outputRouterControllerProvider.notifier).reset();
    }

    if (mounted) {
      // Use pop to go back in navigation stack (not replace entire stack)
      if (context.canPop()) {
        context.pop();
      } else {
        // Fallback if there's nothing to pop to
        context.go(Routes.home);
      }
    }
  }

  Widget _buildClassicTerminalView() {
    return BentoTerminalView(
      onResize: _handleResize,
    );
  }

  Widget _buildSemanticBlocksView() {
    final brightness = Theme.of(context).brightness;
    final colors = TerminalColors.forBrightness(brightness);

    return Column(
      children: [
        // Block list takes most of the space
        Expanded(
          flex: 2,
          child: BlockListView(
            onRerunCommand: _handleRerunCommand,
          ),
        ),
        // Visual separator between blocks and terminal
        Container(
          height: 1,
          color: colors.foreground.withValues(alpha: 0.3),
        ),
        // Terminal input area - larger for better usability
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
            ),
            child: BentoTerminalView(
              onResize: _handleResize,
              autofocus: true,
            ),
          ),
        ),
      ],
    );
  }

  void _toggleViewMode() {
    // Toggle the semantic blocks feature flag
    // In a real app, this would update user preferences
    // For now, we just show a snackbar explaining the feature
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('View mode toggle - configure in settings'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(String action) {
    final blockController = ref.read(blockListControllerProvider.notifier);

    switch (action) {
      case 'collapse_all':
        blockController.collapseAll();
      case 'expand_all':
        blockController.expandAll();
      case 'clear_blocks':
        _showClearBlocksConfirmation();
    }
  }

  Future<void> _showClearBlocksConfirmation() async {
    final blockState = ref.read(blockListControllerProvider);
    final blockCount = blockState.blocks.length;

    if (blockCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No blocks to clear'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Blocks?'),
        content: Text(
          'This will delete $blockCount block${blockCount == 1 ? '' : 's'} '
          'and their command history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(blockListControllerProvider.notifier).clearBlocks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Cleared $blockCount block${blockCount == 1 ? '' : 's'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleRerunCommand(String command) {
    // Re-execute the command
    final controller = ref.read(terminalControllerProvider.notifier);
    controller.write('$command\n');
  }

  void _handleResize(TerminalDimensions dimensions) {
    debugPrint(
      'Terminal resized: ${dimensions.columns}x${dimensions.rows}',
    );
  }

  void _handleKey(String key) {
    final controller = ref.read(terminalControllerProvider.notifier);
    final config = ref.read(terminalConfigProvider);

    // Build the actual key to send
    String keyToSend;

    if (_ctrlActive && key.length == 1) {
      // Convert to control character (e.g., 'c' -> Ctrl+C = 0x03)
      final char = key.codeUnitAt(0);
      if (char >= 0x61 && char <= 0x7A) {
        // a-z
        keyToSend = String.fromCharCode(char - 0x60);
      } else if (char >= 0x41 && char <= 0x5A) {
        // A-Z
        keyToSend = String.fromCharCode(char - 0x40);
      } else {
        keyToSend = key;
      }
    } else if (_altActive && key.length == 1) {
      // Send Alt as Escape prefix
      keyToSend = '\x1b$key';
    } else {
      keyToSend = key;
    }

    // If semantic blocks enabled, route through output router for Ctrl+C detection
    if (config.enableSemanticBlocks) {
      ref.read(outputRouterControllerProvider.notifier).processInput(keyToSend);
    }

    // Send to terminal/SSH
    controller.write(keyToSend);

    // Reset modifiers after use (one-shot mode)
    setState(() {
      _ctrlActive = false;
      _altActive = false;
    });
  }
}

/// Connection status indicator in app bar.
class _ConnectionStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(
      terminalControllerProvider.select((_) {
        return ref.read(terminalControllerProvider.notifier).isSSHConnected;
      }),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Icon(
        isConnected ? Icons.cloud_done : Icons.cloud_off,
        color: isConnected ? Colors.green : Colors.red,
        size: 20,
      ),
    );
  }
}
