// @telos L1:function:lib/features/ai/data/services:remote_ai_service

import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';
import 'remote_ai_exceptions.dart';
import 'remote_backend.dart';

/// AI service implementation for remote backends (Ollama or cloud proxy).
///
/// Routes all AI requests through an SSH connection to the remote host.
/// The active [RemoteBackend] determines how requests are executed:
/// - [OllamaBackend]: curl to localhost Ollama server
/// - [CloudProxyBackend]: curl to cloud APIs using remote host's env vars
///
/// Handles SSH lifecycle (connect/disconnect/reconnect) and backend switching.
///
/// ## Connection Lifecycle
///
/// ```
/// Connected → [onDisconnected] → Disconnected → [onReconnected] → Connected
///                                      ↓
///                              generateCommand() throws
///                              RemoteDisconnectedException
/// ```
///
/// After [dispose], the service cannot be reconnected. The SSH client
/// reference is nulled to prevent use-after-dispose.
class RemoteAiService implements AiService {
  /// Creates a remote AI service bound to an active SSH connection.
  ///
  /// [client] - Active SSH client for executing remote commands.
  /// [backend] - The backend (Ollama or cloud proxy) to delegate to.
  RemoteAiService({
    required SSHClient client,
    required RemoteBackend backend,
  })  : _client = client,
        _backend = backend,
        _isConnected = true;

  SSHClient? _client;
  RemoteBackend _backend;
  bool _isConnected;
  bool _isDisposed = false;

  /// The active backend (Ollama or cloud proxy).
  RemoteBackend get backend => _backend;

  /// Whether this service is bound to an active SSH session.
  bool get isConnected => _isConnected && !_isDisposed;

  /// Switch to a different backend/provider.
  ///
  /// Call this when the user selects a different remote AI provider
  /// (e.g., switching from Ollama to Anthropic cloud proxy).
  void switchBackend(RemoteBackend newBackend) {
    _backend = newBackend;
    debugPrint(
        '[RemoteAiService] Switched backend to: ${newBackend.displayName}');
  }

  /// Handle SSH disconnection.
  ///
  /// Marks the service as unavailable. All subsequent calls to
  /// [generateCommand], [generateCommandStream], and [summarizeOutput]
  /// will throw [RemoteDisconnectedException] until [onReconnected] is called.
  void onDisconnected() {
    _isConnected = false;
    debugPrint('[RemoteAiService] SSH disconnected');
  }

  /// Handle SSH reconnection.
  ///
  /// Updates the SSH client reference and marks the service as available.
  /// Callers should trigger re-detection after calling this, as the remote
  /// host's available models/providers may have changed.
  void onReconnected(SSHClient newClient) {
    _client = newClient;
    _isConnected = true;
    debugPrint('[RemoteAiService] SSH reconnected');
  }

  /// Validates the service is connected and returns the non-null client.
  ///
  /// Throws appropriate exceptions if the service is disposed, disconnected,
  /// or the client has been nulled out after dispose.
  SSHClient _ensureConnected() {
    if (_isDisposed) {
      throw const AiServiceException(
        'Remote AI service has been disposed',
        code: 'disposed',
      );
    }
    if (!_isConnected || _client == null) {
      throw const RemoteDisconnectedException();
    }
    if (!_backend.isConfigured) {
      throw const AiServiceException(
        'Remote AI backend is not configured',
        code: 'not_configured',
      );
    }
    return _client!;
  }

  @override
  Future<AiSuggestion> generateCommand(String prompt) async {
    final client = _ensureConnected();
    try {
      return await _backend.generateCommand(client, prompt);
    } on AiServiceException {
      rethrow;
    } catch (e) {
      throw AiServiceException(
        'Remote AI generation failed: $e',
        code: 'generation_failed',
        originalError: e,
        isRetryable: true,
      );
    }
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(String prompt) async* {
    final SSHClient client;
    try {
      client = _ensureConnected();
    } on AiServiceException catch (e) {
      yield AiStreamError(e.message, code: e.code);
      return;
    }

    try {
      yield* _backend.generateCommandStream(client, prompt);
    } on AiServiceException catch (e) {
      yield AiStreamError(e.message, code: e.code);
    } catch (e) {
      yield AiStreamError(
        'Remote AI streaming failed: $e',
        code: 'stream_error',
        originalError: e,
      );
    }
  }

  @override
  Future<String> summarizeOutput(String command, String output) async {
    final client = _ensureConnected();
    try {
      return await _backend.summarizeOutput(client, command, output);
    } on AiServiceException {
      rethrow;
    } catch (e) {
      throw AiServiceException(
        'Remote AI summarization failed: $e',
        code: 'summarization_failed',
        originalError: e,
        isRetryable: true,
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (_isDisposed || !_isConnected) return false;
    return _backend.isConfigured;
  }

  @override
  AiPrivacyMode get privacyMode => AiPrivacyMode.remote;

  @override
  String get serviceName => 'Remote (${_backend.displayName})';

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _isConnected = false;
    _client = null; // Release SSH client reference to prevent use-after-dispose
    debugPrint('[RemoteAiService] Disposed');
  }
}
