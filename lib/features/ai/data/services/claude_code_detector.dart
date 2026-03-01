// @telos L1:function:lib/features/ai/data/services:claude_code_detector

import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../utils/ssh_utils.dart';

/// Result of Claude Code detection on a remote host.
class ClaudeCodeDetectionResult {
  const ClaudeCodeDetectionResult({
    required this.detected,
    this.version,
  });

  final bool detected;
  final String? version;

  static const notDetected = ClaudeCodeDetectionResult(detected: false);
}

/// Detects whether Claude Code is installed on a remote SSH host.
///
/// Checks for `~/.claude/.credentials` file existence, indicating
/// Claude Code is installed and authenticated. This is distinct from
/// `ANTHROPIC_API_KEY` — a user may have a Claude Max subscription
/// via Claude Code but no raw API key.
///
/// Like [EnvProviderDetector], this never reads credential values.
/// Detection only checks file existence via `test -f`.
class ClaudeCodeDetector {
  const ClaudeCodeDetector();

  static const _sentinel = 'CLAUDE_CODE_FOUND';

  /// Detect Claude Code on the remote host.
  Future<ClaudeCodeDetectionResult> detect(SSHClient client) async {
    try {
      const detectionCmd =
          'test -d ~/.claude && test -f ~/.claude/.credentials '
          '&& echo "$_sentinel"';

      final session = await client
          .execute(detectionCmd)
          .timeout(const Duration(seconds: 10));

      final stdout = await SshUtils.collectOutput(session.stdout);
      final exitCode = await session.exitCode;

      if (exitCode != 0 || !stdout.contains(_sentinel)) {
        debugPrint('[ClaudeCodeDetector] Not found (exit=$exitCode)');
        return ClaudeCodeDetectionResult.notDetected;
      }

      debugPrint('[ClaudeCodeDetector] Found Claude Code');
      final version = await _getVersion(client);

      return ClaudeCodeDetectionResult(
        detected: true,
        version: version,
      );
    } on TimeoutException {
      debugPrint('[ClaudeCodeDetector] Detection timed out');
      return ClaudeCodeDetectionResult.notDetected;
    } catch (e) {
      debugPrint('[ClaudeCodeDetector] Detection error: $e');
      return ClaudeCodeDetectionResult.notDetected;
    }
  }

  Future<String?> _getVersion(SSHClient client) async {
    try {
      final session = await client
          .execute('claude --version 2>/dev/null')
          .timeout(const Duration(seconds: 5));

      final stdout = await SshUtils.collectOutput(session.stdout);
      final exitCode = await session.exitCode;

      if (exitCode != 0) return null;

      final version = stdout.trim();
      if (version.isEmpty || version == 'unknown') return null;
      return version;
    } catch (_) {
      return null;
    }
  }
}
