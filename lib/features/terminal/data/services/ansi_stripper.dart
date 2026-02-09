// @telos L1:function:lib/features/terminal/data/services:ansi_stripper

/// Utility for stripping ANSI escape sequences from terminal output.
///
/// Handles various escape sequence types including:
/// - CSI sequences (colors, cursor movement)
/// - OSC sequences (window titles, shell integration)
/// - Other control sequences
class AnsiStripper {
  AnsiStripper._();

  /// Regex to match ANSI escape sequences.
  ///
  /// Handles:
  /// - CSI sequences: \x1B[...m (colors, cursor movement, etc.)
  /// - OSC sequences: \x1B]...(\x07|\x1B\\) (window titles, shell integration)
  /// - Simple escapes: \x1B followed by single character
  static final _ansiEscapeRegex = RegExp(
    // CSI sequences: ESC [ ... final_byte
    r'\x1B\[[0-?]*[ -/]*[@-~]'
    // OSC sequences: ESC ] ... (BEL or ST)
    // These are used by Starship, iTerm2, etc. for shell integration
    r'|\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)?'
    // APC, DCS, PM, SOS sequences: ESC (_, P, ^, X) ... ST
    r'|\x1B[_P\^X][^\x1B]*(?:\x1B\\)?'
    // Simple escape sequences: ESC followed by single char
    r'|\x1B[@-Z\\-_]',
  );

  /// Regex to match orphaned/partial escape sequences.
  ///
  /// These can occur when buffering splits an escape sequence across chunks:
  /// - Orphaned OSC start: ]...BEL or ]...ST (missing leading ESC)
  /// - Bare control characters: BEL, etc.
  static final _orphanedSequenceRegex = RegExp(
    // Orphaned OSC with BEL terminator: ] + digits + ; + content + BEL
    // This catches shell integration markers like ]133;A\x07 or ]0;title\x07
    // The BEL terminator makes this safe - normal text won't have BEL
    r'\]\d+;[^\x07]*\x07'
    // Orphaned OSC at line start: ]> pattern from Starship prompt markers
    // Use lookbehind to match only at start of string or after newline
    r'|(?<=^|\n)\][>\d;]*'
    // Bare BEL character (always safe to remove)
    r'|\x07'
    // C1 control characters (0x80-0x9F) - sometimes used as alternatives to ESC sequences
    r'|[\x80-\x9F]',
    multiLine: true,
  );

  /// Strips ANSI escape codes from text.
  ///
  /// This removes:
  /// - Color codes (SGR sequences)
  /// - Cursor movement sequences
  /// - OSC sequences (window titles, shell integration markers)
  /// - Other terminal control sequences
  /// - Orphaned partial sequences from buffer splits
  static String strip(String text) {
    var result = text.replaceAll(_ansiEscapeRegex, '');
    result = result.replaceAll(_orphanedSequenceRegex, '');
    return result;
  }
}
