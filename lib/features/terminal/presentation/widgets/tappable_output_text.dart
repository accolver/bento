// @telos L2:contract:component-block-widget

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/usecases/parse_tappable_elements.dart';

/// Renders terminal output with tappable elements (IPs, URLs, file paths).
///
/// Detects patterns in the text and makes them interactive with context menus.
class TappableOutputText extends StatelessWidget {
  const TappableOutputText({
    required this.text,
    this.style,
    this.maxLines,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final elements = parseTappableElements(text);

    if (elements.isEmpty) {
      return SelectableText(
        text,
        style: style,
        maxLines: maxLines,
      );
    }

    return _buildRichText(context, elements);
  }

  Widget _buildRichText(BuildContext context, List<TappableElement> elements) {
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final linkStyle = baseStyle.copyWith(
      color: Colors.lightBlueAccent,
      decoration: TextDecoration.underline,
      decorationColor: Colors.lightBlueAccent.withValues(alpha: 0.5),
    );

    for (final element in elements) {
      // Add text before this element
      if (element.startOffset > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, element.startOffset),
            style: baseStyle,
          ),
        );
      }

      // Add the tappable element
      spans.add(
        TextSpan(
          text: element.value,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTapDown = (details) {
              _showContextMenu(context, details.globalPosition, element);
            },
        ),
      );

      lastEnd = element.endOffset;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: baseStyle,
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    TappableElement element,
  ) {
    final items = _getMenuItems(element);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items,
    ).then((value) {
      if (value != null && context.mounted) {
        _handleMenuAction(context, value, element);
      }
    });
  }

  List<PopupMenuItem<String>> _getMenuItems(TappableElement element) {
    switch (element.type) {
      case TappableType.ipAddress:
        return const [
          PopupMenuItem(value: 'copy', child: Text('Copy IP')),
          PopupMenuItem(value: 'ssh', child: Text('SSH to this host')),
          PopupMenuItem(value: 'ping', child: Text('Ping')),
        ];
      case TappableType.url:
        return const [
          PopupMenuItem(value: 'copy', child: Text('Copy URL')),
          PopupMenuItem(value: 'open', child: Text('Open in browser')),
        ];
      case TappableType.filePath:
        return const [
          PopupMenuItem(value: 'copy', child: Text('Copy path')),
          PopupMenuItem(value: 'cat', child: Text('View file (cat)')),
          PopupMenuItem(value: 'ls', child: Text('List directory (ls -la)')),
        ];
      case TappableType.email:
        return const [
          PopupMenuItem(value: 'copy', child: Text('Copy email')),
        ];
      case TappableType.uuid:
        return const [
          PopupMenuItem(value: 'copy', child: Text('Copy UUID')),
        ];
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    TappableElement element,
  ) {
    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: element.value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: ${element.value}'),
            duration: const Duration(seconds: 2),
          ),
        );
      case 'open':
        final uri = Uri.tryParse(element.value);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      case 'ssh':
        // Copy as SSH command for now
        Clipboard.setData(ClipboardData(text: 'ssh ${element.value}'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: ssh ${element.value}'),
            duration: const Duration(seconds: 2),
          ),
        );
      case 'ping':
        Clipboard.setData(ClipboardData(text: 'ping ${element.value}'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: ping ${element.value}'),
            duration: const Duration(seconds: 2),
          ),
        );
      case 'cat':
        Clipboard.setData(ClipboardData(text: 'cat ${element.value}'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: cat ${element.value}'),
            duration: const Duration(seconds: 2),
          ),
        );
      case 'ls':
        Clipboard.setData(ClipboardData(text: 'ls -la ${element.value}'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: ls -la ${element.value}'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }
}
