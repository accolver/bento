// @telos L1:function:lib/features/terminal/presentation/screens:terminal_screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xterm/xterm.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/terminal_colors.dart';
import '../../../ai/domain/entities/ai_config.dart';
import '../../../ai/presentation/providers/ai_providers.dart';
import '../../../ai/presentation/screens/ai_setup_wizard.dart';
import '../../../ai/presentation/widgets/ai_fab.dart';
import '../../../ai/presentation/widgets/ai_ghostwriter_panel.dart';
import '../../domain/entities/terminal_config.dart';
import '../../domain/entities/terminal_mode.dart';
import '../../domain/entities/view_mode.dart';
import '../providers/block_provider.dart';
import '../providers/output_router_provider.dart';
import '../providers/terminal_config_provider.dart';
import '../providers/terminal_display_mode_provider.dart';
import '../providers/terminal_provider.dart';
import '../providers/view_mode_provider.dart';
import '../widgets/block_list_view.dart';
import '../widgets/modifier_keys_bar.dart';
import '../widgets/terminal_view.dart';
import '../widgets/view_mode_toggle.dart';

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
    this.embedded = false,
    this.onDisconnect,
  });

  /// Optional title for the terminal (e.g., connection name).
  final String? title;

  /// Whether this screen is embedded in another screen (e.g., multi-session).
  /// When true, the app bar is not rendered.
  final bool embedded;

  /// Callback when disconnect is requested (for embedded mode).
  final VoidCallback? onDisconnect;

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize blocks for this session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBlocks();
    });
  }

  void _initializeBlocks() {
    final config = ref.read(terminalConfigProvider);
    if (config.enableSemanticBlocks) {
      // Load any existing blocks for this session
      ref.read(blockListControllerProvider.notifier).loadBlocks();

      // Force initialization of the output router if it hasn't been created yet
      // The router sets up its terminal callback in build(), so we just need to access it
      ref.read(outputRouterControllerProvider);

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
    // Watch the current display mode (blocks, tui, or classic)
    final displayMode = ref.watch(currentTerminalModeProvider);
    // Watch the user's selected view mode
    final viewMode = ref.watch(viewModeControllerProvider);

    // When embedded, just return the terminal content without Scaffold/AppBar
    // Back button handling is done by the parent (MultiSessionTerminalScreen)
    if (widget.embedded) {
      return Container(
        color: colors.background,
        child: Stack(
          children: [
            Column(
              children: [
                // Main content area - switches instantly based on display mode
                Expanded(
                  child: GestureDetector(
                    // Ensure tapping on the terminal area requests focus
                    onTap: () {
                      // This ensures keyboard appears when tapping the terminal
                      FocusScope.of(context).requestFocus();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: _buildMainContent(displayMode, viewMode, config),
                  ),
                ),

                // Modifier keys bar - always visible
                ModifierKeysBar(onKey: _handleKey),
              ],
            ),

            // AI FAB - visible in split/blocks modes, hidden in TUI/fullTerminal
            if (_shouldShowAiFab(displayMode, viewMode))
              Positioned(
                right: 16,
                bottom: 70, // Above modifier bar
                child: AiFab(
                  onPressed: () => _showAiPanel(context),
                ),
              ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackButton();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: _buildAppBar(colors, config, displayMode),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Main content area - switches instantly based on display mode
                  Expanded(
                    child: _buildMainContent(displayMode, viewMode, config),
                  ),

                  // Modifier keys bar - always visible
                  ModifierKeysBar(onKey: _handleKey),
                ],
              ),

              // AI FAB - visible in split/blocks modes, hidden in TUI/fullTerminal
              if (_shouldShowAiFab(displayMode, viewMode))
                Positioned(
                  right: 16,
                  bottom: 70, // Above modifier bar
                  child: AiFab(
                    onPressed: () => _showAiPanel(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Determines if the AI FAB should be visible.
  ///
  /// Hidden in TUI mode and full terminal view to avoid obstructing content.
  bool _shouldShowAiFab(TerminalMode displayMode, ViewMode viewMode) {
    // Hide in TUI mode (vim, htop, etc.)
    if (displayMode == TerminalMode.tui) {
      return false;
    }

    // Hide in full terminal view
    if (viewMode == ViewMode.fullTerminal) {
      return false;
    }

    // Show in split view and full blocks view
    return true;
  }

  /// Shows the AI Ghostwriter bottom sheet panel.
  ///
  /// If AI is not configured, shows the setup wizard first.
  Future<void> _showAiPanel(BuildContext context) async {
    // Check if AI is configured - await the async provider
    final configAsync = ref.read(aiConfigStateProvider);

    // If still loading, wait for it to complete
    final AiConfig config;
    if (configAsync.isLoading || configAsync.hasError) {
      // Force a fresh read and wait for it
      config = await ref.read(aiConfigStateProvider.future);
    } else {
      config = configAsync.valueOrNull ?? AiConfig.unconfigured();
    }

    if (!config.isConfigured) {
      // Show setup wizard first
      await AiSetupWizard.show(context);
      // After wizard closes, check if now configured
      final newConfig = await ref.read(aiConfigStateProvider.future);
      if (newConfig.isConfigured && mounted) {
        // Now show the AI panel
        _showAiPanelDirect(context);
      }
      return;
    }

    _showAiPanelDirect(context);
  }

  /// Shows the AI panel directly (assumes AI is configured).
  void _showAiPanelDirect(BuildContext context) {
    // Clear any previous input
    ref.read(aiInputProvider.notifier).clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AiGhostwriterPanel(
          onExecute: (command) {
            Navigator.of(context).pop();
            _executeAiCommand(command);
          },
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Executes a command generated by AI.
  void _executeAiCommand(String command) {
    final controller = ref.read(terminalControllerProvider.notifier);
    final config = ref.read(terminalConfigProvider);

    // If semantic blocks enabled, route through output router to create a block
    if (config.enableSemanticBlocks) {
      final outputRouter = ref.read(outputRouterControllerProvider.notifier);
      // Send each character to build up the input buffer
      for (final char in command.split('')) {
        outputRouter.processInput(char);
      }
      // Send Enter to trigger block creation
      outputRouter.processInput('\n');
    }

    // Write the command to the terminal
    controller.write('$command\n');

    // Request focus back on the terminal view after a short delay
    // to allow the bottom sheet dismissal animation to complete
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // Find and focus the terminal view
        FocusScope.of(context).requestFocus();
      }
    });
  }

  /// Handles Android back button press.
  ///
  /// In TUI mode, sends Escape to the terminal.
  /// In other modes, shows a confirmation dialog before disconnecting.
  void _handleBackButton() {
    final displayMode = ref.read(currentTerminalModeProvider);

    if (displayMode == TerminalMode.tui) {
      // In TUI mode, send Escape to the terminal
      final terminal = ref.read(terminalControllerProvider);
      terminal.keyInput(TerminalKey.escape);
    } else {
      // In blocks/classic mode, show confirmation dialog
      _showDisconnectConfirmation();
    }
  }

  /// Shows a confirmation dialog before disconnecting.
  Future<void> _showDisconnectConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect?'),
        content: const Text(
          'Press back again to disconnect from this session.',
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
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _handleDisconnect();
    }
  }

  /// Builds the main content area based on current display mode and user's view mode.
  ///
  /// When in TUI mode (detected automatically), always shows full-screen terminal.
  /// Otherwise, respects the user's selected [ViewMode]:
  /// - [ViewMode.split]: Shows BlockListView + terminal input area
  /// - [ViewMode.fullTerminal]: Shows full-screen terminal view
  /// - [ViewMode.fullBlocks]: Shows full-screen blocks view
  Widget _buildMainContent(
    TerminalMode displayMode,
    ViewMode viewMode,
    TerminalConfig config,
  ) {
    // TUI mode always takes precedence (for vim, htop, etc.)
    if (displayMode == TerminalMode.tui) {
      return _buildFullScreenTerminalView();
    }

    // Otherwise, use the user's selected view mode
    switch (viewMode) {
      case ViewMode.split:
        return _buildSemanticBlocksView();
      case ViewMode.fullTerminal:
        return _buildClassicTerminalView();
      case ViewMode.fullBlocks:
        return _buildFullBlocksView();
    }
  }

  PreferredSizeWidget _buildAppBar(
    TerminalColorScheme colors,
    TerminalConfig config,
    TerminalMode displayMode,
  ) {
    // In TUI mode, show minimal app bar (no view mode controls)
    final isInTuiMode = displayMode == TerminalMode.tui;
    final viewMode = ref.watch(viewModeControllerProvider);
    final showsBlocks = viewMode.showsBlocks;

    return AppBar(
      title: Text(widget.title ?? 'Terminal'),
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _handleDisconnect,
      ),
      actions: [
        // Connection status indicator - always visible
        _ConnectionStatusIndicator(),
        // View mode toggle (hidden in TUI mode)
        if (!isInTuiMode) const ViewModeCycleButton(),
        // Collapse/expand all (only when blocks are visible, hidden in TUI mode)
        if (!isInTuiMode && showsBlocks)
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

  /// Builds full-screen terminal view for TUI applications.
  ///
  /// This is used when a TUI app (vim, htop, Claude Code, etc.) activates
  /// the alternate screen buffer. The terminal fills the available space
  /// to allow proper TUI rendering.
  Widget _buildFullScreenTerminalView() {
    return BentoTerminalView(
      onResize: _handleResize,
      autofocus: true,
    );
  }

  /// Builds split view with blocks at top and terminal input at bottom.
  Widget _buildSemanticBlocksView() {
    final brightness = Theme.of(context).brightness;
    final colors = TerminalColors.forBrightness(brightness);
    final config = ref.watch(terminalConfigProvider);

    // Calculate fixed height for ~6 lines of terminal
    // charHeight includes line spacing, typically fontSize * 1.2
    final terminalInputHeight = config.charHeight * 6 + 8; // 6 lines + padding

    return Column(
      children: [
        // Block list takes remaining space
        Expanded(
          child: BlockListView(
            onRerunCommand: _handleRerunCommand,
          ),
        ),
        // Terminal input area - fixed height for 6 lines
        // ClipRect ensures terminal content doesn't overflow above the border
        ClipRect(
          child: Container(
            height: terminalInputHeight,
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(
                top: BorderSide(
                  color: colors.foreground.withValues(alpha: 0.3),
                  width: 1,
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

  /// Builds full-screen blocks view (no terminal input area).
  ///
  /// Shows only the semantic blocks list taking the full available space.
  /// Users can tap on command blocks to rerun them.
  Widget _buildFullBlocksView() {
    return BlockListView(
      onRerunCommand: _handleRerunCommand,
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

    // If semantic blocks enabled, route through output router for Ctrl+C detection
    if (config.enableSemanticBlocks) {
      ref.read(outputRouterControllerProvider.notifier).processInput(key);
    }

    // Send to terminal/SSH
    controller.write(key);
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
