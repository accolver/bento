// @telos L1:function:lib/features/ai/data/services:remote_backend

import 'package:dartssh2/dartssh2.dart';

import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';

/// Abstract backend that [RemoteAiService] delegates to.
///
/// Two implementations:
/// - [OllamaBackend]: Uses Ollama's API on the remote host
/// - [CloudProxyBackend]: Proxies cloud API calls through SSH
abstract class RemoteBackend {
  /// Execute a command generation request via SSH.
  Future<AiSuggestion> generateCommand(
    SSHClient client,
    String prompt,
  );

  /// Execute a streaming command generation via SSH.
  Stream<AiStreamEvent> generateCommandStream(
    SSHClient client,
    String prompt,
  );

  /// Execute an output summarization request via SSH.
  Future<String> summarizeOutput(
    SSHClient client,
    String command,
    String output,
  );

  /// Whether this backend is properly configured and ready to use.
  bool get isConfigured;

  /// Display name for UI (e.g., "Ollama (llama3:8b)" or "Claude (Anthropic)").
  String get displayName;

  /// Privacy description for the user.
  String get privacyDescription;
}
