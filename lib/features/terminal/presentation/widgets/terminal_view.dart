// @telos L1:function:lib/features/terminal/presentation/widgets:terminal_view

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../domain/entities/terminal_config.dart';
import '../providers/terminal_config_provider.dart';
import '../providers/terminal_provider.dart';

/// A widget that displays a terminal emulator.
///
/// Wraps the xterm TerminalView widget with configuration from providers
/// and handles sizing, input, and clipboard operations.
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
            fontFamily: config.fontFamily,
          ),
          autofocus: widget.autofocus,
          onSecondaryTapDown: _handleSecondaryTap,
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

      // Resize the terminal backend
      final terminal = ref.read(terminalControllerProvider);
      terminal.resize(dimensions.columns, dimensions.rows);

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
