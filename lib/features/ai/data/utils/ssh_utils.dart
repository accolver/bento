// @telos L1:function:lib/features/ai/data/utils:ssh_utils

import 'dart:convert';

/// Shared SSH utility functions used across remote AI backends and detectors.
class SshUtils {
  SshUtils._();

  /// Collect all output from an SSH stream into a string.
  ///
  /// Decodes UTF-8 bytes from the stream and concatenates them.
  /// Used by all remote AI backends and detectors.
  static Future<String> collectOutput(Stream<List<int>> stream) async {
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
    }
    return buffer.toString();
  }
}
