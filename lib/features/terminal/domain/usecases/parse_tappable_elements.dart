// @telos L1:function:lib/features/terminal/domain/usecases:parse_tappable_elements

import 'package:equatable/equatable.dart';

/// Types of tappable elements that can be detected in terminal output.
enum TappableType { ipAddress, filePath, url, email, uuid }

/// A detected tappable element in terminal output.
class TappableElement extends Equatable {
  const TappableElement({
    required this.type,
    required this.value,
    required this.startOffset,
    required this.endOffset,
  });

  final TappableType type;
  final String value;
  final int startOffset;
  final int endOffset;

  @override
  List<Object?> get props => [type, value, startOffset, endOffset];
}

/// Parses terminal output text to find tappable elements (IPs, URLs, file paths, etc.).
List<TappableElement> parseTappableElements(String text) {
  final elements = <TappableElement>[];

  // IP addresses (IPv4)
  final ipRegex = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
    r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b',
  );

  // URLs
  final urlRegex = RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+',
  );

  // File paths (Unix-style absolute paths)
  final pathRegex = RegExp(
    r'''(?:^|[\s"'(])(/(?:[^\s"')\x00]+))''',
    multiLine: true,
  );

  // Email addresses
  final emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
  );

  // Match URLs first (higher priority - they may contain IPs)
  for (final match in urlRegex.allMatches(text)) {
    elements.add(
      TappableElement(
        type: TappableType.url,
        value: match.group(0)!,
        startOffset: match.start,
        endOffset: match.end,
      ),
    );
  }

  // Match IPs
  for (final match in ipRegex.allMatches(text)) {
    elements.add(
      TappableElement(
        type: TappableType.ipAddress,
        value: match.group(0)!,
        startOffset: match.start,
        endOffset: match.end,
      ),
    );
  }

  // Match file paths - use group(1) to get just the path
  for (final match in pathRegex.allMatches(text)) {
    final path = match.group(1);
    if (path != null && path.length > 1) {
      // Avoid false positives - require at least 2 path segments
      if (path.contains('/') && path != '/') {
        final pathStart = match.start + (match.group(0)!.length - path.length);
        elements.add(
          TappableElement(
            type: TappableType.filePath,
            value: path,
            startOffset: pathStart,
            endOffset: pathStart + path.length,
          ),
        );
      }
    }
  }

  // Match emails
  for (final match in emailRegex.allMatches(text)) {
    elements.add(
      TappableElement(
        type: TappableType.email,
        value: match.group(0)!,
        startOffset: match.start,
        endOffset: match.end,
      ),
    );
  }

  // Sort by start offset and remove overlaps
  elements.sort((a, b) => a.startOffset.compareTo(b.startOffset));
  return _removeOverlaps(elements);
}

/// Remove overlapping elements (keep the first one encountered).
List<TappableElement> _removeOverlaps(List<TappableElement> elements) {
  if (elements.isEmpty) return elements;

  final result = <TappableElement>[elements.first];
  for (var i = 1; i < elements.length; i++) {
    if (elements[i].startOffset >= result.last.endOffset) {
      result.add(elements[i]);
    }
  }
  return result;
}
