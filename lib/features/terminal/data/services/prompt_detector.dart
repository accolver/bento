// @telos L1:function:lib/features/terminal/data/services:prompt_detector

/// Result of prompt detection.
class PromptDetectionResult {
  const PromptDetectionResult({
    required this.hasPrompt,
    this.promptEnd,
    this.command,
  });

  /// Whether a prompt was detected.
  final bool hasPrompt;

  /// Index where the prompt ends (command starts).
  final int? promptEnd;

  /// Extracted command text (if any).
  final String? command;

  /// No prompt detected.
  static const none = PromptDetectionResult(hasPrompt: false);
}

/// Detects shell prompts in terminal output to identify command boundaries.
///
/// Supports common shell prompts for bash, zsh, fish, and custom patterns.
/// Used to determine when a new command block should be created.
class PromptDetector {
  PromptDetector({
    List<RegExp>? customPatterns,
  }) : _customPatterns = customPatterns ?? [];

  final List<RegExp> _customPatterns;

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

  /// Common shell prompt patterns.
  ///
  /// These patterns are designed to match ONLY actual shell prompts,
  /// not random output that happens to contain prompt-like characters.
  ///
  /// Key characteristics of prompts vs regular output:
  /// - Prompts usually start at the beginning of a line
  /// - Prompts contain user@host or path followed by prompt symbol
  /// - The prompt symbol is followed by space (for typing)
  /// - Regular output (like ls) with `->` arrows should NOT match
  static final List<RegExp> defaultPatterns = [
    // Standard bash/zsh prompt: user@host:path$ or user@host path %
    // Must start with user@host pattern
    RegExp(r'^[\w.-]+@[\w.-]+[:\s][~\w/.\s-]*[$#%]\s*'),

    // Bracketed prompt: [user@host path]$
    RegExp(r'^\[[\w@.\s/-]+\][$#%]\s*'),

    // Simple prompts at start of line: $ # %
    RegExp(r'^[~\w/.-]*[$#%]\s+'),

    // Fish-style prompt at start of line: ~/path>
    // Note: Must be at start to avoid matching symlinks (file -> target)
    RegExp(r'^[~\w/.-]+>\s*'),

    // PS1 with path at start: ~/path$ or ~/path %
    RegExp(r'^[~][/\w.-]*\s*[$#%]\s*'),

    // Numbered prompt: [1] $
    RegExp(r'^\[\d+\]\s*[$#%]\s*'),

    // Time-prefixed: [HH:MM:SS] user@host $
    RegExp(r'^\[\d{2}:\d{2}(:\d{2})?\]\s*[\w@.\s:-]*[$#%]\s*'),

    // Git branch in prompt: (branch) $
    RegExp(r'\([^)]+\)\s*[$#%]\s+'),

    // Virtualenv prefix: (env) user@host $
    RegExp(r'^\([^)]+\)\s*[\w@.\s:-]*[$#%]\s*'),

    // Starship-style: lines with ❯ or ➜
    // These are distinctive Unicode chars not found in normal output
    // ❯ (U+276F), ➜ (U+279C) are the most common Starship prompt symbols
    //
    // Starship has two common configurations:
    // 1. Single-line: ~/repo main ❯ ls (❯ somewhere in the line)
    // 2. Multi-line: first line has path/info, second line is just "❯ " or "❯ ls"
    //
    // Pattern matches ❯/➜ anywhere in line, followed by optional space
    // This is safe because these symbols are very rare in normal output
    RegExp(r'[❯➜\u276F\u279C]\s*'), // Starship prompt symbol anywhere
  ];

  /// Detects if the given line contains a shell prompt.
  ///
  /// Returns a [PromptDetectionResult] indicating whether a prompt was found
  /// and where it ends (so the command can be extracted).
  PromptDetectionResult detectPrompt(String line) {
    // Strip ANSI escape codes for prompt detection
    final cleanLine = _stripAnsiCodes(line);

    // Try custom patterns first
    for (final pattern in _customPatterns) {
      final match = pattern.firstMatch(cleanLine);
      if (match != null) {
        final command = _extractCommand(cleanLine, match.end);
        return PromptDetectionResult(
          hasPrompt: true,
          promptEnd: match.end,
          command: command,
        );
      }
    }

    // Try default patterns
    for (final pattern in defaultPatterns) {
      final match = pattern.firstMatch(cleanLine);
      if (match != null) {
        // Find the LAST prompt symbol to extract command after it
        // This handles prompts where path comes before the symbol
        final command = _extractCommandAfterPromptSymbol(cleanLine);
        return PromptDetectionResult(
          hasPrompt: true,
          promptEnd: match.end,
          command: command,
        );
      }
    }

    return PromptDetectionResult.none;
  }

  /// Extracts command by finding the prompt symbol and taking text after it.
  ///
  /// Uses stricter matching to avoid false positives from output like
  /// symlink arrows (->).
  String? _extractCommandAfterPromptSymbol(String line) {
    // Primary prompt symbols (excluding > which conflicts with symlinks)
    // $ % # are traditional, ❯ ➜ are modern (Starship)
    final promptSymbols = RegExp(r'[$#%❯➜\u276F\u279C]');

    int lastSymbolIndex = -1;
    for (final match in promptSymbols.allMatches(line)) {
      lastSymbolIndex = match.end;
    }

    if (lastSymbolIndex == -1) return null;

    // Extract everything after the last prompt symbol
    final afterSymbol = line.substring(lastSymbolIndex).trim();
    return afterSymbol.isEmpty ? null : afterSymbol;
  }

  /// Strips ANSI escape codes and control characters from a string.
  String _stripAnsiCodes(String input) {
    // Remove ANSI escape sequences
    var cleaned = input.replaceAll(_ansiEscapeRegex, '');
    // Remove carriage returns (terminals use \r\n line endings)
    cleaned = cleaned.replaceAll('\r', '');
    return cleaned;
  }

  /// Detects prompts in multi-line output.
  ///
  /// Scans the output for prompt patterns and returns information about
  /// the last detected prompt (most recent command).
  PromptDetectionResult detectInOutput(String output) {
    final lines = output.split('\n');

    // Scan from the end to find the most recent prompt
    for (var i = lines.length - 1; i >= 0; i--) {
      final result = detectPrompt(lines[i]);
      if (result.hasPrompt) {
        return result;
      }
    }

    return PromptDetectionResult.none;
  }

  /// Extracts the command text following a prompt.
  String? _extractCommand(String line, int promptEnd) {
    if (promptEnd >= line.length) return null;

    final command = line.substring(promptEnd).trim();
    return command.isEmpty ? null : command;
  }

  /// Detects if output indicates a command has completed.
  ///
  /// This looks for a new prompt appearing after output, which typically
  /// indicates the previous command has finished.
  bool detectCommandCompletion(String recentOutput) {
    // Look for a prompt in the last few lines
    final lines = recentOutput.split('\n');
    final lastLines =
        lines.length > 3 ? lines.sublist(lines.length - 3) : lines;

    for (final line in lastLines) {
      if (detectPrompt(line).hasPrompt) {
        return true;
      }
    }

    return false;
  }

  /// Detects Ctrl+C cancellation in output.
  bool detectCancellation(String output) {
    // Common cancellation indicators
    return output.contains('^C') ||
        output.contains('Interrupted') ||
        output.contains('SIGINT');
  }

  /// Attempts to extract exit code from shell output.
  ///
  /// Some shells/prompts include exit code. This is a best-effort detection.
  /// Returns null if exit code cannot be determined from output alone.
  int? detectExitCode(String output) {
    // Look for common exit code patterns
    // Pattern: "exit code: N" or "exited with N" or "[N]" at start of prompt
    final patterns = [
      RegExp(r'exit(?:ed with|ed| code[:\s]+)\s*(\d+)', caseSensitive: false),
      RegExp(r'\[(\d+)\]\s*[$#%>]'), // [exitcode] prompt
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(output);
      if (match != null && match.groupCount >= 1) {
        return int.tryParse(match.group(1) ?? '');
      }
    }

    return null;
  }

  /// Creates a detector with additional custom patterns.
  PromptDetector withCustomPatterns(List<String> patterns) {
    final regexPatterns = patterns.map((p) => RegExp(p)).toList();
    return PromptDetector(
      customPatterns: [..._customPatterns, ...regexPatterns],
    );
  }
}
