// @telos L1:function:lib/features/ai/data/services:ollama_detector

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/ollama_model.dart';
import '../utils/ssh_utils.dart';

/// Detects Ollama instances running on SSH-connected servers.
///
/// Probes `localhost:11434/api/tags` via SSH exec to check if Ollama
/// is running and what models are available. Detection is silent —
/// failures are never surfaced to the user.
///
/// This is one of two detection strategies used by [RemoteAiDetector].
/// The other is [EnvProviderDetector] for cloud API keys.
class OllamaDetector {
  const OllamaDetector();

  /// Probe an SSH client for Ollama.
  ///
  /// Executes `curl localhost:11434/api/tags` via SSH exec.
  /// Returns list of available models if Ollama is found, null if not.
  ///
  /// Silently returns null on any failure (timeout, curl missing,
  /// Ollama not running, invalid response, etc.).
  Future<List<OllamaModel>?> detect(SSHClient client) async {
    try {
      // Wrap the entire detection (execute + stdout collection + exitCode)
      // in a single timeout. Previously only execute() was timed, so a
      // slow stdout stream or hanging exitCode could block indefinitely.
      return await _detectWithClient(client)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      debugPrint('[OllamaDetector] Detection timed out');
      return null;
    } catch (e) {
      debugPrint('[OllamaDetector] Detection failed: $e');
      return null;
    }
  }

  /// Internal detection logic, wrapped by [detect] with a timeout.
  Future<List<OllamaModel>?> _detectWithClient(SSHClient client) async {
    final session = await client.execute(
      'curl -s --connect-timeout 2 localhost:11434/api/tags',
    );

    final stdout = await SshUtils.collectOutput(session.stdout);
    final exitCode = await session.exitCode;

    if (exitCode != 0) return null;
    if (stdout.isEmpty) return null;

    final json = jsonDecode(stdout) as Map<String, dynamic>;
    final models = _parseModels(json);

    return models.isEmpty ? null : models;
  }

  /// Parse Ollama model list from /api/tags JSON response.
  ///
  /// Uses [OllamaModel.fromJson] which has @JsonKey annotations mapping
  /// the Ollama API field names (`size` → `sizeBytes`, `modified_at` → `modifiedAt`).
  List<OllamaModel> _parseModels(Map<String, dynamic> json) {
    final modelsList = json['models'] as List? ?? [];
    return modelsList
        .map((m) {
          try {
            return OllamaModel.fromJson(m as Map<String, dynamic>);
          } catch (e) {
            debugPrint('[OllamaDetector] Failed to parse model: $e');
            return null;
          }
        })
        .whereType<OllamaModel>()
        .where((m) => m.name.isNotEmpty)
        .toList();
  }
}
