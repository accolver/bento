// @telos L1:function:lib/features/ai/data/services:env_provider_detector

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/remote_ai_detection.dart';
import '../../domain/entities/remote_ai_provider.dart';

/// Detects AI provider API keys configured as environment variables
/// on SSH-connected hosts.
///
/// Checks a curated list of known provider environment variables using
/// `test -n "$VAR_NAME"` — this only checks if the variable is set,
/// never reads its value. API keys never leave the remote machine.
///
/// This is one of two detection strategies used by [RemoteAiDetector].
/// The other is [OllamaDetector] for local Ollama instances.
class EnvProviderDetector {
  const EnvProviderDetector();

  /// Probe an SSH client for known AI provider env vars.
  ///
  /// Executes a batched `test -n "$VAR"` command to check which provider
  /// API keys are set. Never reads key values — only checks existence.
  ///
  /// Returns list of detected providers sorted by quality rank,
  /// or empty list if none found.
  ///
  /// The [detectionMethod] output parameter indicates whether the default
  /// shell or a login shell fallback was needed.
  Future<
      ({
        List<DetectedCloudProvider> providers,
        RemoteDetectionMethod method
      })> detect(SSHClient client) async {
    // Try direct detection first
    final directResult = await _detectWithCommand(
      client,
      _buildDetectionCommand(),
    );

    if (directResult.isNotEmpty) {
      return (
        providers: directResult,
        method: RemoteDetectionMethod.direct,
      );
    }

    // Fallback: try bash login shell
    final bashResult = await _detectWithCommand(
      client,
      "bash -l -c '${_buildDetectionCommand()}'",
    );

    if (bashResult.isNotEmpty) {
      return (
        providers: bashResult,
        method: RemoteDetectionMethod.bashLogin,
      );
    }

    // Fallback: try zsh login shell
    final zshResult = await _detectWithCommand(
      client,
      "zsh -l -c '${_buildDetectionCommand()}'",
    );

    if (zshResult.isNotEmpty) {
      return (
        providers: zshResult,
        method: RemoteDetectionMethod.zshLogin,
      );
    }

    // Fallback: try bash interactive login shell.
    // ~/.bashrc is only sourced for interactive shells, so `bash -l -c`
    // alone won't find env vars set there. Adding -i forces interactive mode.
    final bashInteractiveResult = await _detectWithCommand(
      client,
      "bash -li -c '${_buildDetectionCommand()}'",
    );

    if (bashInteractiveResult.isNotEmpty) {
      return (
        providers: bashInteractiveResult,
        method: RemoteDetectionMethod.bashInteractiveLogin,
      );
    }

    // Fallback: try zsh interactive login shell.
    // ~/.zshrc is only sourced for interactive shells, so `zsh -l -c`
    // alone won't find env vars set there. This is the most common case
    // on macOS where users export API keys in ~/.zshrc.
    final zshInteractiveResult = await _detectWithCommand(
      client,
      "zsh -li -c '${_buildDetectionCommand()}'",
    );

    if (zshInteractiveResult.isNotEmpty) {
      return (
        providers: zshInteractiveResult,
        method: RemoteDetectionMethod.zshInteractiveLogin,
      );
    }

    return (
      providers: <DetectedCloudProvider>[],
      method: RemoteDetectionMethod.direct,
    );
  }

  /// Build the batched shell command that checks all known env vars.
  ///
  /// Uses `test -n` to check existence without reading values.
  /// Each check outputs only the variable name if set.
  /// A sentinel line marks command completion.
  String _buildDetectionCommand() {
    final allVars = RemoteProviderRegistry.allEnvVarNames;
    final checks = allVars
        .map((v) => '(test -n "\$$v" && echo "$v") 2>/dev/null')
        .join('; ');
    return '$checks; echo "---ENV_CHECK_DONE---"';
  }

  /// Execute a detection command and parse the results.
  Future<List<DetectedCloudProvider>> _detectWithCommand(
    SSHClient client,
    String command,
  ) async {
    try {
      final session =
          await client.execute(command).timeout(const Duration(seconds: 5));

      final stdout = await _collectOutput(session.stdout);

      // Verify the command completed (sentinel present)
      if (!stdout.contains('---ENV_CHECK_DONE---')) {
        debugPrint('[EnvProviderDetector] Command did not complete');
        return [];
      }

      return _parseDetectionOutput(stdout);
    } on TimeoutException {
      debugPrint('[EnvProviderDetector] Detection timed out');
      return [];
    } catch (e) {
      debugPrint('[EnvProviderDetector] Detection failed: $e');
      return [];
    }
  }

  /// Parse the detection output into a list of detected providers.
  ///
  /// Handles deduplication: if multiple env vars map to the same provider,
  /// only the first (preferred) one is included.
  List<DetectedCloudProvider> _parseDetectionOutput(String stdout) {
    final lines = stdout
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != '---ENV_CHECK_DONE---')
        .toList();

    // Deduplicate: first env var per provider wins
    final detected = <RemoteCloudProvider, DetectedCloudProvider>{};

    for (final varName in lines) {
      final config = RemoteProviderRegistry.forEnvVar(varName);
      if (config != null && !detected.containsKey(config.provider)) {
        detected[config.provider] = DetectedCloudProvider(
          provider: config.provider,
          envVarName: varName,
          displayName: config.displayName,
          defaultModel: config.defaultModel,
          qualityRank: config.qualityRank,
        );
      }
    }

    // Sort by quality rank (1 = best)
    final results = detected.values.toList()
      ..sort((a, b) => a.qualityRank.compareTo(b.qualityRank));

    return results;
  }

  /// Collect all output from an SSH stream into a string.
  Future<String> _collectOutput(Stream<List<int>> stream) async {
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
    }
    return buffer.toString();
  }
}
