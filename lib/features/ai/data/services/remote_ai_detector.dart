// @telos L1:function:lib/features/ai/data/services:remote_ai_detector

import 'dart:async';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/remote_ai_detection.dart';
import 'env_provider_detector.dart';
import 'ollama_detector.dart';

/// Unified AI detection orchestrator for SSH-connected hosts.
///
/// Combines [OllamaDetector] and [EnvProviderDetector] to discover
/// all available AI capabilities on a remote host in a single detection
/// pass after SSH connection establishment.
///
/// Results are cached per host with a 5-minute expiry.
class RemoteAiDetector {
  /// Creates a detector with optional custom sub-detectors.
  ///
  /// Falls back to default [OllamaDetector] and [EnvProviderDetector]
  /// implementations when none are provided.
  RemoteAiDetector({
    OllamaDetector? ollamaDetector,
    EnvProviderDetector? envProviderDetector,
  })  : _ollamaDetector = ollamaDetector ?? const OllamaDetector(),
        _envProviderDetector =
            envProviderDetector ?? const EnvProviderDetector();

  final OllamaDetector _ollamaDetector;
  final EnvProviderDetector _envProviderDetector;

  /// Cache of detection results by host ID.
  final Map<String, RemoteAiDetectionResult> _cache = {};

  /// Stream controller for detection events.
  final StreamController<RemoteAiDetectionEvent> _eventController =
      StreamController<RemoteAiDetectionEvent>.broadcast();

  /// Stream of detection events.
  Stream<RemoteAiDetectionEvent> get detectionEvents => _eventController.stream;

  /// Run full detection on the given SSH client.
  ///
  /// Probes for both Ollama and cloud provider env vars in parallel.
  /// Caches the result and emits a detection event.
  ///
  /// [hostId] - Identifier for the SSH host (used for caching).
  /// [client] - Active SSH client connection.
  Future<RemoteAiDetectionResult> detect({
    required String hostId,
    required SSHClient client,
  }) async {
    debugPrint('[RemoteAiDetector] Starting detection for $hostId');

    // Run both detections in parallel
    final ollamaFuture = _ollamaDetector.detect(client);
    final envFuture = _envProviderDetector.detect(client);

    final ollamaModels = await ollamaFuture;
    final envResult = await envFuture;

    final detectionResult = RemoteAiDetectionResult(
      hostId: hostId,
      ollamaModels: ollamaModels ?? [],
      cloudProviders: envResult.providers,
      checkedAt: DateTime.now(),
      detectionMethod: envResult.method,
    );

    // Cache the result
    _cache[hostId] = detectionResult;

    // Emit appropriate event (guard against post-dispose adds)
    if (detectionResult.hasAnyProvider) {
      debugPrint('[RemoteAiDetector] Detected ${detectionResult.providerCount} '
          'providers on $hostId');
      _emitEvent(RemoteAiDetectedEvent(
        hostId: hostId,
        result: detectionResult,
      ));
    } else {
      debugPrint('[RemoteAiDetector] No AI providers found on $hostId');
      _emitEvent(RemoteAiNotFoundEvent(
        hostId: hostId,
        reason: 'No Ollama or cloud provider env vars detected',
      ));
    }

    return detectionResult;
  }

  /// Get cached detection result for a host.
  ///
  /// Returns null if no cached result exists or the cache is stale.
  RemoteAiDetectionResult? getCachedResult(String hostId) {
    final cached = _cache[hostId];
    if (cached == null) return null;
    if (cached.isStale) {
      _cache.remove(hostId);
      return null;
    }
    return cached;
  }

  /// Clear cached detection result for a host.
  ///
  /// Called when SSH disconnects to invalidate stale data.
  void clearCache(String hostId) {
    _cache.remove(hostId);
  }

  /// Clear all cached results.
  void clearAllCaches() {
    _cache.clear();
  }

  /// Safely emit an event, guarding against post-dispose calls.
  ///
  /// Detection runs asynchronously and may complete after dispose() is called.
  /// Without this guard, StreamController.add() after close() throws.
  void _emitEvent(RemoteAiDetectionEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Dispose of resources.
  void dispose() {
    _eventController.close();
  }
}
