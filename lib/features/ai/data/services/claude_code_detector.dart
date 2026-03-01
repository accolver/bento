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
/// Checks for the `claude` CLI binary via `command -v claude`. This works
/// on both macOS (where credentials are in the Keychain) and Linux (where
/// credentials may be in `~/.claude/.credentials`).
///
/// This is distinct from checking `ANTHROPIC_API_KEY` — a user may have
/// a Claude Max subscription via Claude Code but no raw API key set.
///
/// Like [EnvProviderDetector], this never reads credential values.
/// Detection only checks CLI existence, and optionally probes whether
/// the session is authenticated via `claude --print-access-token`.
class ClaudeCodeDetector {
  const ClaudeCodeDetector();

  static const _sentinel = 'CLAUDE_CODE_FOUND';

  /// Detect Claude Code on the remote host.
  ///
  /// Detection strategy:
  /// 1. Check if `claude` CLI is in PATH (`command -v claude`)
  /// 2. Verify it has a valid session (`claude --print-access-token`)
  /// 3. Get version string (`claude --version`)
  Future<ClaudeCodeDetectionResult> detect(SSHClient client) async {
    try {
      // Check if claude CLI exists in PATH
      const detectionCmd =
          'command -v claude >/dev/null 2>&1 && echo "$_sentinel"';

      final session = await client
          .execute(detectionCmd)
          .timeout(const Duration(seconds: 10));

      final stdout = await SshUtils.collectOutput(session.stdout);
      final exitCode = await session.exitCode;

      if (exitCode != 0 || !stdout.contains(_sentinel)) {
        debugPrint('[ClaudeCodeDetector] CLI not found (exit=$exitCode)');
        return ClaudeCodeDetectionResult.notDetected;
      }

      debugPrint('[ClaudeCodeDetector] CLI found, checking auth...');

      // Verify the session is authenticated by trying to get an access token
      final hasAuth = await _hasValidAuth(client);
      if (!hasAuth) {
        debugPrint('[ClaudeCodeDetector] CLI found but not authenticated');
        return ClaudeCodeDetectionResult.notDetected;
      }

      debugPrint('[ClaudeCodeDetector] Found authenticated Claude Code');
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

  /// Check if Claude Code has a valid authenticated session.
  ///
  /// Runs `claude --print-access-token` which returns a token if
  /// the user is logged in. We don't read the token value — just
  /// check that the command succeeds (exit 0) and produces output.
  Future<bool> _hasValidAuth(SSHClient client) async {
    try {
      final session = await client
          .execute('claude --print-access-token 2>/dev/null | '
              'grep -c . >/dev/null 2>&1 && echo "AUTH_OK"')
          .timeout(const Duration(seconds: 10));

      final stdout = await SshUtils.collectOutput(session.stdout);
      return stdout.contains('AUTH_OK');
    } catch (_) {
      return false;
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
