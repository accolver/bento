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
  ///
  /// Each step wraps the ENTIRE flow (execute + collect output + exit code)
  /// in a single timeout to prevent hanging if the remote process stalls.
  Future<ClaudeCodeDetectionResult> detect(SSHClient client) async {
    try {
      // Step 1: Check if claude CLI exists in PATH
      final cliFound = await _checkCliExists(client);
      if (!cliFound) {
        return ClaudeCodeDetectionResult.notDetected;
      }

      debugPrint('[ClaudeCodeDetector] CLI found, checking auth...');

      // Step 2: Verify authenticated session
      final hasAuth = await _hasValidAuth(client);
      if (!hasAuth) {
        debugPrint('[ClaudeCodeDetector] CLI found but not authenticated');
        return ClaudeCodeDetectionResult.notDetected;
      }

      debugPrint('[ClaudeCodeDetector] Found authenticated Claude Code');

      // Step 3: Get version (non-critical)
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

  /// Check if `claude` CLI is in PATH on the remote host.
  ///
  /// Wraps the entire flow (execute + stdout + exitCode) in a single
  /// 10-second timeout to prevent hanging.
  Future<bool> _checkCliExists(SSHClient client) async {
    try {
      return await Future(() async {
        const detectionCmd =
            'command -v claude >/dev/null 2>&1 && echo "$_sentinel"';

        final session = await client.execute(detectionCmd);
        final stdout = await SshUtils.collectOutput(session.stdout);
        final exitCode = await session.exitCode;

        if (exitCode != 0 || !stdout.contains(_sentinel)) {
          debugPrint('[ClaudeCodeDetector] CLI not found (exit=$exitCode)');
          return false;
        }
        return true;
      }).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      debugPrint('[ClaudeCodeDetector] CLI check timed out');
      return false;
    } catch (e) {
      debugPrint('[ClaudeCodeDetector] CLI check error: $e');
      return false;
    }
  }

  /// Check if Claude Code has a valid authenticated session.
  ///
  /// Runs `claude --print-access-token` which returns a token if
  /// the user is logged in. We don't read the token value — just
  /// check that the command succeeds (exit 0) and produces output.
  ///
  /// Wraps the entire flow in a single 10-second timeout.
  Future<bool> _hasValidAuth(SSHClient client) async {
    try {
      return await Future(() async {
        final session = await client.execute(
          'claude --print-access-token 2>/dev/null | '
          'grep -c . >/dev/null 2>&1 && echo "AUTH_OK"',
        );
        final stdout = await SshUtils.collectOutput(session.stdout);
        return stdout.contains('AUTH_OK');
      }).timeout(const Duration(seconds: 10));
    } catch (_) {
      return false;
    }
  }

  /// Get Claude Code version string.
  ///
  /// Wraps the entire flow in a single 5-second timeout.
  Future<String?> _getVersion(SSHClient client) async {
    try {
      return await Future(() async {
        final session = await client.execute('claude --version 2>/dev/null');
        final stdout = await SshUtils.collectOutput(session.stdout);
        final exitCode = await session.exitCode;

        if (exitCode != 0) return null;

        final version = stdout.trim();
        if (version.isEmpty || version == 'unknown') return null;
        return version;
      }).timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }
}
