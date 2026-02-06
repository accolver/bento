// @telos L1:function:lib/features/terminal/presentation/widgets:terminal_view

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../domain/entities/terminal_config.dart';
import '../providers/terminal_config_provider.dart';
import '../providers/terminal_provider.dart';

/// Returns true if running on a mobile platform (Android or iOS).
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// A widget that displays a terminal emulator.
///
/// Wraps the xterm TerminalView widget with configuration from providers
/// and handles sizing, input, and clipboard operations.
///
/// Note: Android back button handling is done at the screen level
/// (TerminalScreen) to properly handle TUI mode vs normal mode.
class BentoTerminalView extends ConsumerStatefulWidget {
  const BentoTerminalView({
    super.key,
    this.onResize,
    this.autofocus = true,
  });

  /// Callback when terminal dimensions change.
  final void Function(TerminalDimensions dimensions)? onResize;

  /// Whether to autofocus the terminal on mount.
  final bool autofocus;

  @override
  ConsumerState<BentoTerminalView> createState() => _BentoTerminalViewState();
}

class _BentoTerminalViewState extends ConsumerState<BentoTerminalView> {
  final _terminalKey = GlobalKey();
  TerminalDimensions? _lastDimensions;

  @override
  Widget build(BuildContext context) {
    final terminal = ref.watch(terminalControllerProvider);
    final config = ref.watch(terminalConfigProvider);
    final brightness = Theme.of(context).brightness;
    final theme = ref.watch(terminalThemeProvider(brightness));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Schedule dimension calculation after layout
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculateAndNotifyDimensions(constraints.biggest, config);
        });

        return TerminalView(
          key: _terminalKey,
          terminal,
          theme: theme,
          textStyle: TerminalStyle(
            fontSize: config.fontSize,
            // Use Nerd Font as primary - contains all standard chars + special icons
            // The Nerd Font includes complete coverage so minimal fallback needed
            fontFamily: config.fontFamily,
            // Minimal fallback - Nerd Font should have everything needed
            // Only fall back for emoji which are in different Unicode blocks
            fontFamilyFallback: const [
              'Noto Color Emoji', // For actual emoji (not Nerd Font icons)
            ],
          ),
          autofocus: widget.autofocus,
          onSecondaryTapDown: _handleSecondaryTap,
          // Enable delete/backspace detection on mobile platforms.
          // Mobile soft keyboards don't always emit hardware delete events,
          // so xterm needs this workaround to detect backspace properly.
          deleteDetection: _isMobilePlatform,
          // Use text keyboard type for better terminal compatibility.
          // The default emailAddress type can cause issues with some characters.
          keyboardType: TextInputType.text,
        );
      },
    );
  }

  void _calculateAndNotifyDimensions(Size size, TerminalConfig config) {
    // Estimate character width based on font
    // This is approximate - xterm handles precise measurement internally
    final charWidth = config.fontSize * 0.6; // Monospace approximation
    final charHeight = config.charHeight;

    final dimensions = calculateTerminalDimensions(
      availableSize: size,
      charWidth: charWidth,
      charHeight: charHeight,
      minColumns: config.minColumns,
      minRows: config.minRows,
    );

    // Only notify if dimensions changed
    if (_lastDimensions != dimensions) {
      _lastDimensions = dimensions;

      // Resize the terminal via controller (which also resizes SSH PTY)
      final controller = ref.read(terminalControllerProvider.notifier);
      controller.resize(dimensions.columns, dimensions.rows);

      // Notify callback
      widget.onResize?.call(dimensions);
    }
  }

  void _handleSecondaryTap(TapDownDetails details, CellOffset offset) {
    // Show context menu for copy/paste
    _showContextMenu(details.globalPosition);
  }

  void _showContextMenu(Offset position) {
    // Note: Copy is handled by xterm's built-in selection mechanism
    // We only provide paste here since selection state is internal to TerminalView
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem(
          value: 'paste',
          child: Text('Paste'),
        ),
      ],
    ).then((value) {
      if (value == 'paste') {
        _paste();
      }
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final controller = ref.read(terminalControllerProvider.notifier);
      controller.write(data!.text!);
    }
  }
}
