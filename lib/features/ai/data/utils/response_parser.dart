// @telos L1:function:lib/features/ai/data/utils:response_parser

/// Shared utility for parsing AI-generated command responses.
///
/// Used by both [OllamaBackend] and [CloudProxyBackend] to extract
/// the command and explanation from AI responses.
class ResponseParser {
  ResponseParser._();

  /// Parse a command and explanation from AI response content.
  ///
  /// The AI is instructed to output the command on the first line and
  /// an explanation on the second line. This parser handles various
  /// response formats including markdown code blocks, `$` prefixes,
  /// and `#` comment prefixes.
  ///
  /// Returns a tuple of (command, explanation).
  static (String, String) parseCommandAndExplanation(String content) {
    var text = content.trim();

    // Remove markdown code blocks
    if (text.startsWith('```')) {
      final lines = text.split('\n');
      if (lines.length > 1) lines.removeAt(0);
      if (lines.isNotEmpty && lines.last.trim() == '```') lines.removeLast();
      text = lines.join('\n').trim();
    }

    // Split into non-empty lines
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return ('', 'Generated command');

    // First line is the command
    var command = lines.first.trim();
    // Strip common prefixes
    if (command.startsWith(r'$ ')) command = command.substring(2);
    if (command.startsWith('# ')) command = command.substring(2);

    // Remaining lines form the explanation
    final explanation = lines.length > 1
        ? lines.sublist(1).join(' ').trim()
        : 'Generated command';

    return (command, explanation.isEmpty ? 'Generated command' : explanation);
  }
}
