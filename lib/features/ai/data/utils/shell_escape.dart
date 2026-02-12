// @telos L1:function:lib/features/ai/data/utils:shell_escape

/// Utility for safely escaping strings for shell execution over SSH.
///
/// When proxying API calls through SSH, request bodies (JSON) must be
/// embedded in shell commands. This class handles escaping to prevent
/// injection and ensure correct parsing by the remote shell.
class ShellEscape {
  ShellEscape._();

  /// Escape a string for use in a single-quoted shell context.
  ///
  /// Strategy: Replace `'` with `'\''` (end quote, escaped quote, start quote).
  /// This is the safest approach for embedding arbitrary content in shell
  /// commands because single-quoted strings in POSIX shells have no special
  /// characters except the closing quote itself.
  ///
  /// Examples:
  /// - `hello` → `hello`
  /// - `it's` → `it'\''s`
  /// - `{"key": "value"}` → `{"key": "value"}` (unchanged, no single quotes)
  /// - `don't "stop"` → `don'\''t "stop"` (only single quotes escaped)
  static String escape(String input) {
    return input.replaceAll("'", r"'\''");
  }

  /// Escape a string and wrap it in single quotes for shell use.
  ///
  /// Returns a string like `'escaped content'` ready for embedding
  /// in a shell command.
  static String quote(String input) {
    return "'${escape(input)}'";
  }
}
