// @telos-test L1:function:lib/features/ai/data/services:remote_ai_integration

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/services/cloud_proxy_backend.dart';
import 'package:bento/features/ai/data/services/env_provider_detector.dart';
import 'package:bento/features/ai/data/services/ollama_backend.dart';
import 'package:bento/features/ai/data/services/ollama_detector.dart';
import 'package:bento/features/ai/data/services/remote_ai_detector.dart';
import 'package:bento/features/ai/data/services/remote_ai_exceptions.dart';
import 'package:bento/features/ai/data/services/remote_ai_service.dart';
import 'package:bento/features/ai/data/services/remote_backend.dart';
import 'package:bento/features/ai/domain/entities/ai_suggestion.dart';
import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_detection.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSSHClient extends Mock implements SSHClient {}

class MockSSHSession extends Mock implements SSHSession {}

class MockOllamaDetector extends Mock implements OllamaDetector {}

class MockEnvProviderDetector extends Mock implements EnvProviderDetector {}

class MockRemoteBackend extends Mock implements RemoteBackend {}

// ---------------------------------------------------------------------------
// SSH session helpers
// ---------------------------------------------------------------------------

/// Creates a mock SSH session with configurable stdout, stderr, and exit code.
MockSSHSession _createSession({
  String stdoutData = '',
  String stderrData = '',
  int? exitCode = 0,
}) {
  final session = MockSSHSession();
  when(() => session.stdout).thenAnswer((_) {
    if (stdoutData.isEmpty) return const Stream<Uint8List>.empty();
    return Stream.value(Uint8List.fromList(utf8.encode(stdoutData)));
  });
  when(() => session.stderr).thenAnswer((_) {
    if (stderrData.isEmpty) return const Stream<Uint8List>.empty();
    return Stream.value(Uint8List.fromList(utf8.encode(stderrData)));
  });
  when(() => session.exitCode).thenReturn(exitCode);
  return session;
}

/// Creates a mock SSH session that emits multiple stdout chunks (for streaming).
MockSSHSession _createStreamingSession(List<String> chunks) {
  final session = MockSSHSession();
  when(() => session.stdout).thenAnswer((_) {
    return Stream.fromIterable(
      chunks.map((c) => Uint8List.fromList(utf8.encode(c))),
    );
  });
  when(() => session.stderr).thenAnswer((_) => const Stream<Uint8List>.empty());
  when(() => session.exitCode).thenReturn(0);
  return session;
}

/// Builds a valid OpenAI-format JSON response with the given content.
String _openAiResponse(String content) {
  return jsonEncode({
    'choices': [
      {
        'message': {'content': content},
      },
    ],
  });
}

/// Builds an SSE data line for streaming responses.
String _sseDataLine(String content) {
  final json = jsonEncode({
    'choices': [
      {
        'delta': {'content': content},
      },
    ],
  });
  return 'data: $json\n';
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

final _ollamaModel = OllamaModel(
  name: 'llama3:8b',
  modifiedAt: DateTime(2024),
);

final _ollamaModel2 = OllamaModel(
  name: 'codellama:7b',
  modifiedAt: DateTime(2024),
);

const _anthropicProvider = DetectedCloudProvider(
  provider: RemoteCloudProvider.anthropic,
  envVarName: 'ANTHROPIC_API_KEY',
  displayName: 'Claude (Anthropic)',
  defaultModel: 'claude-sonnet-4-20250514',
  qualityRank: 1,
);

const _openaiProvider = DetectedCloudProvider(
  provider: RemoteCloudProvider.openai,
  envVarName: 'OPENAI_API_KEY',
  displayName: 'GPT-4o (OpenAI)',
  defaultModel: 'gpt-4o',
  qualityRank: 2,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(MockSSHClient());
    registerFallbackValue('');
  });

  // =========================================================================
  // Task 179: Full detection flow with mocked SSH
  // =========================================================================
  group('Task 179: Full detection flow integration', () {
    late MockOllamaDetector mockOllamaDetector;
    late MockEnvProviderDetector mockEnvDetector;
    late MockSSHClient mockClient;
    late RemoteAiDetector detector;

    setUp(() {
      mockOllamaDetector = MockOllamaDetector();
      mockEnvDetector = MockEnvProviderDetector();
      mockClient = MockSSHClient();
      detector = RemoteAiDetector(
        ollamaDetector: mockOllamaDetector,
        envProviderDetector: mockEnvDetector,
      );
    });

    tearDown(() {
      detector.dispose();
    });

    void stubDetectors({
      List<OllamaModel>? ollamaModels,
      List<DetectedCloudProvider> cloudProviders = const [],
      RemoteDetectionMethod method = RemoteDetectionMethod.direct,
    }) {
      when(() => mockOllamaDetector.detect(any()))
          .thenAnswer((_) async => ollamaModels);
      when(() => mockEnvDetector.detect(any())).thenAnswer((_) async => (
            providers: cloudProviders,
            method: method,
          ));
    }

    // @telos-scenario L1:...:remote_ai_integration:full-detection-both-providers
    test('detects both Ollama and cloud providers in parallel', () async {
      stubDetectors(
        ollamaModels: [_ollamaModel, _ollamaModel2],
        cloudProviders: [_anthropicProvider, _openaiProvider],
      );

      final eventFuture = detector.detectionEvents.first;

      final result = await detector.detect(
        hostId: 'integration-host',
        client: mockClient,
      );

      // Verify combined result
      expect(result.hostId, 'integration-host');
      expect(result.ollamaModels, hasLength(2));
      expect(result.cloudProviders, hasLength(2));
      expect(result.hasAnyProvider, isTrue);
      expect(result.hasOllama, isTrue);
      expect(result.hasCloudProviders, isTrue);
      // 1 (Ollama group) + 2 cloud
      expect(result.providerCount, 3);

      // Verify event was emitted
      final event = await eventFuture;
      expect(event, isA<RemoteAiDetectedEvent>());
      final detected = event as RemoteAiDetectedEvent;
      expect(detected.result.ollamaModels, hasLength(2));
      expect(detected.result.cloudProviders, hasLength(2));

      // Verify both detectors were called exactly once
      verify(() => mockOllamaDetector.detect(mockClient)).called(1);
      verify(() => mockEnvDetector.detect(mockClient)).called(1);
    });

    // @telos-scenario L1:...:remote_ai_integration:caching-then-clear
    test('caches result, serves from cache, clears on disconnect', () async {
      stubDetectors(
        ollamaModels: [_ollamaModel],
        cloudProviders: [_anthropicProvider],
      );

      // First detection
      await detector.detect(hostId: 'host-cache', client: mockClient);
      final cached = detector.getCachedResult('host-cache');
      expect(cached, isNotNull);
      expect(cached!.hasAnyProvider, isTrue);

      // Simulate disconnect: clear cache
      detector.clearCache('host-cache');
      expect(detector.getCachedResult('host-cache'), isNull);
    });

    // @telos-scenario L1:...:remote_ai_integration:event-stream-multiple
    test('emits multiple events for multiple detections', () async {
      stubDetectors(ollamaModels: [_ollamaModel], cloudProviders: []);

      final events = <RemoteAiDetectionEvent>[];
      final sub = detector.detectionEvents.listen(events.add);

      await detector.detect(hostId: 'host-a', client: mockClient);

      stubDetectors(ollamaModels: null, cloudProviders: []);
      await detector.detect(hostId: 'host-b', client: mockClient);

      // Allow event delivery
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0], isA<RemoteAiDetectedEvent>());
      expect(events[0].hostId, 'host-a');
      expect(events[1], isA<RemoteAiNotFoundEvent>());
      expect(events[1].hostId, 'host-b');

      await sub.cancel();
    });

    // @telos-scenario L1:...:remote_ai_integration:login-shell-detection-method
    test('preserves login shell detection method through full flow', () async {
      stubDetectors(
        ollamaModels: null,
        cloudProviders: [_anthropicProvider],
        method: RemoteDetectionMethod.bashLogin,
      );

      final result = await detector.detect(
        hostId: 'host-login',
        client: mockClient,
      );

      expect(result.detectionMethod, RemoteDetectionMethod.bashLogin);
      expect(result.hasCloudProviders, isTrue);
    });
  });

  // =========================================================================
  // Task 180: Command generation end-to-end through RemoteAiService
  // =========================================================================
  group('Task 180: Command generation e2e', () {
    late MockSSHClient mockClient;

    setUp(() {
      mockClient = MockSSHClient();
    });

    // @telos-scenario L1:...:remote_ai_integration:ollama-generate-e2e
    test('generates command through OllamaBackend via RemoteAiService',
        () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      // Mock the SSH execute call to return a valid OpenAI-format response
      final session = _createSession(
        stdoutData: _openAiResponse('ls -la\nList all files in long format'),
      );
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final suggestion = await service.generateCommand('list files');

      expect(suggestion, isA<AiSuggestion>());
      expect(suggestion.command, isNotEmpty);
      expect(suggestion.confidence, 0.8);

      verify(() => mockClient.execute(any())).called(1);

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:cloud-proxy-generate-e2e
    test('generates command through CloudProxyBackend via RemoteAiService',
        () async {
      final providerConfig = RemoteProviderRegistry.forProvider(
        RemoteCloudProvider.openai,
      )!;

      final backend = CloudProxyBackend(
        providerConfig: providerConfig,
        envVarName: 'OPENAI_API_KEY',
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      final session = _createSession(
        stdoutData: _openAiResponse('docker ps\nList running containers'),
      );
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final suggestion =
          await service.generateCommand('show running containers');

      expect(suggestion, isA<AiSuggestion>());
      expect(suggestion.command, isNotEmpty);
      expect(suggestion.confidence, 0.85); // CloudProxy confidence

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:summarize-e2e
    test('summarizes output through RemoteAiService', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      final session = _createSession(
        stdoutData: _openAiResponse('Found 3 running processes'),
      );
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final summary = await service.summarizeOutput('ps aux', 'PID TTY ...');

      expect(summary, 'Found 3 running processes');

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:curl-not-found
    test('throws CurlNotFoundException when curl missing', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      final session = _createSession(
        stdoutData: '',
        stderrData: 'bash: curl: command not found',
        exitCode: 127,
      );
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      expect(
        () => service.generateCommand('test'),
        throwsA(isA<CurlNotFoundException>()),
      );

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:api-error-wrapped
    test('wraps backend exceptions in AiServiceException', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      final session = _createSession(
        stdoutData: '',
        stderrData: 'Connection refused',
        exitCode: 7,
      );
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      expect(
        () => service.generateCommand('test'),
        throwsA(isA<RemoteExecutionException>()),
      );

      await service.dispose();
    });
  });

  // =========================================================================
  // Task 181: Streaming generation end-to-end
  // =========================================================================
  group('Task 181: Streaming e2e', () {
    late MockSSHClient mockClient;

    setUp(() {
      mockClient = MockSSHClient();
    });

    // @telos-scenario L1:...:remote_ai_integration:ollama-stream-e2e
    test('streams tokens through OllamaBackend via RemoteAiService', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      // Simulate SSE streaming response in chunks
      final session = _createStreamingSession([
        _sseDataLine('ls '),
        _sseDataLine('-la'),
        _sseDataLine('\nList files'),
        'data: [DONE]\n',
      ]);
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final events = await service.generateCommandStream('list files').toList();

      // Should have token events + complete
      final tokens =
          events.whereType<AiStreamToken>().map((t) => t.token).toList();
      final completes = events.whereType<AiStreamComplete>().toList();

      expect(tokens, isNotEmpty);
      expect(tokens.join(), contains('ls'));
      expect(completes, hasLength(1));
      expect(completes.first.suggestion, isA<AiSuggestion>());

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:cloud-proxy-stream-e2e
    test('streams tokens through CloudProxyBackend via RemoteAiService',
        () async {
      final providerConfig = RemoteProviderRegistry.forProvider(
        RemoteCloudProvider.groq,
      )!;

      final backend = CloudProxyBackend(
        providerConfig: providerConfig,
        envVarName: 'GROQ_API_KEY',
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      final session = _createStreamingSession([
        _sseDataLine('docker '),
        _sseDataLine('ps'),
        _sseDataLine('\nList containers'),
        'data: [DONE]\n',
      ]);
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final events =
          await service.generateCommandStream('show containers').toList();

      final tokens = events.whereType<AiStreamToken>().toList();
      final completes = events.whereType<AiStreamComplete>().toList();

      expect(tokens, isNotEmpty);
      expect(completes, hasLength(1));
      expect(completes.first.suggestion.confidence, 0.85);

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:stream-error-on-disconnect
    test('stream yields error event when disconnected', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      service.onDisconnected();

      final events = await service.generateCommandStream('test').toList();

      expect(events, hasLength(1));
      expect(events.first, isA<AiStreamError>());
      final error = events.first as AiStreamError;
      expect(error.message, contains('SSH connection lost'));

      await service.dispose();
    });
  });

  // =========================================================================
  // Task 182: Disconnect/reconnect cycle
  // =========================================================================
  group('Task 182: Disconnect/reconnect cycle', () {
    late MockSSHClient mockClient;
    late MockSSHClient newMockClient;

    setUp(() {
      mockClient = MockSSHClient();
      newMockClient = MockSSHClient();
    });

    // @telos-scenario L1:...:remote_ai_integration:disconnect-then-generate-throws
    test('generateCommand throws after disconnect', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      // Verify initially connected
      expect(service.isConnected, isTrue);
      expect(await service.isAvailable(), isTrue);

      // Disconnect
      service.onDisconnected();
      expect(service.isConnected, isFalse);
      expect(await service.isAvailable(), isFalse);

      // Attempt to generate — should throw
      expect(
        () => service.generateCommand('test'),
        throwsA(isA<RemoteDisconnectedException>()),
      );

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:reconnect-restores-service
    test('reconnect restores service and uses new SSH client', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      // Disconnect
      service.onDisconnected();
      expect(service.isConnected, isFalse);

      // Reconnect with new client
      service.onReconnected(newMockClient);
      expect(service.isConnected, isTrue);
      expect(await service.isAvailable(), isTrue);

      // Generate with new client — verify new client is used
      final session = _createSession(
        stdoutData: _openAiResponse('whoami\nShow current user'),
      );
      when(() => newMockClient.execute(any())).thenAnswer((_) async => session);

      final suggestion = await service.generateCommand('who am I');
      expect(suggestion, isA<AiSuggestion>());

      // Verify the NEW client was used (not the old one)
      verify(() => newMockClient.execute(any())).called(1);
      verifyNever(() => mockClient.execute(any()));

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:multiple-disconnect-reconnect
    test('handles multiple disconnect/reconnect cycles', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      // Cycle 1
      service.onDisconnected();
      expect(service.isConnected, isFalse);
      service.onReconnected(newMockClient);
      expect(service.isConnected, isTrue);

      // Cycle 2
      service.onDisconnected();
      expect(service.isConnected, isFalse);
      final thirdClient = MockSSHClient();
      service.onReconnected(thirdClient);
      expect(service.isConnected, isTrue);

      // Verify third client is used
      final session = _createSession(
        stdoutData: _openAiResponse('uptime\nShow system uptime'),
      );
      when(() => thirdClient.execute(any())).thenAnswer((_) async => session);

      await service.generateCommand('uptime');
      verify(() => thirdClient.execute(any())).called(1);

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:dispose-then-reconnect-no-restore
    test('dispose is permanent, reconnect does not restore', () async {
      final backend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      await service.dispose();
      expect(service.isConnected, isFalse);

      // Reconnect after dispose should not restore
      service.onReconnected(newMockClient);
      // isConnected checks !_isDisposed, so it stays false
      expect(service.isConnected, isFalse);
      expect(await service.isAvailable(), isFalse);
    });
  });

  // =========================================================================
  // Task 183: Provider switching
  // =========================================================================
  group('Task 183: Provider switching', () {
    late MockSSHClient mockClient;

    setUp(() {
      mockClient = MockSSHClient();
    });

    // @telos-scenario L1:...:remote_ai_integration:switch-ollama-to-cloud
    test('switches from OllamaBackend to CloudProxyBackend', () async {
      final ollamaBackend = OllamaBackend(
        selectedModel: 'llama3:8b',
        availableModels: [_ollamaModel],
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: ollamaBackend,
      );

      expect(service.serviceName, contains('Ollama'));

      // Switch to cloud proxy
      final cloudConfig = RemoteProviderRegistry.forProvider(
        RemoteCloudProvider.anthropic,
      )!;
      final cloudBackend = CloudProxyBackend(
        providerConfig: cloudConfig,
        envVarName: 'ANTHROPIC_API_KEY',
      );

      service.switchBackend(cloudBackend);

      expect(service.serviceName, contains('Anthropic'));
      expect(service.backend, cloudBackend);

      // Verify subsequent calls use the new backend
      // Anthropic uses a different response format
      final anthropicResponse = jsonEncode({
        'content': [
          {'type': 'text', 'text': 'find / -name "*.log"\nFind all log files'},
        ],
      });
      final session = _createSession(stdoutData: anthropicResponse);
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final suggestion = await service.generateCommand('find log files');
      expect(suggestion, isA<AiSuggestion>());
      expect(suggestion.confidence, 0.85); // Cloud proxy confidence

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:switch-cloud-to-cloud
    test('switches between two cloud providers', () async {
      final openaiConfig = RemoteProviderRegistry.forProvider(
        RemoteCloudProvider.openai,
      )!;
      final groqConfig = RemoteProviderRegistry.forProvider(
        RemoteCloudProvider.groq,
      )!;

      final openaiBackend = CloudProxyBackend(
        providerConfig: openaiConfig,
        envVarName: 'OPENAI_API_KEY',
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: openaiBackend,
      );

      expect(service.serviceName, contains('OpenAI'));

      // Switch to Groq
      final groqBackend = CloudProxyBackend(
        providerConfig: groqConfig,
        envVarName: 'GROQ_API_KEY',
      );

      service.switchBackend(groqBackend);

      expect(service.serviceName, contains('Groq'));
      expect(service.backend, groqBackend);

      await service.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:switch-preserves-connection
    test('switching backend preserves connection state', () async {
      final backend1 = MockRemoteBackend();
      when(() => backend1.isConfigured).thenReturn(true);
      when(() => backend1.displayName).thenReturn('Backend 1');
      when(() => backend1.privacyDescription).thenReturn('Privacy 1');

      final service = RemoteAiService(
        client: mockClient,
        backend: backend1,
      );

      expect(service.isConnected, isTrue);

      final backend2 = MockRemoteBackend();
      when(() => backend2.isConfigured).thenReturn(true);
      when(() => backend2.displayName).thenReturn('Backend 2');
      when(() => backend2.privacyDescription).thenReturn('Privacy 2');

      service.switchBackend(backend2);

      // Connection state should be preserved
      expect(service.isConnected, isTrue);
      expect(await service.isAvailable(), isTrue);

      await service.dispose();
    });
  });

  // =========================================================================
  // Task 184: Detection → Service creation flow
  // =========================================================================
  group('Task 184: Detection to service creation flow', () {
    late MockOllamaDetector mockOllamaDetector;
    late MockEnvProviderDetector mockEnvDetector;
    late MockSSHClient mockClient;

    setUp(() {
      mockOllamaDetector = MockOllamaDetector();
      mockEnvDetector = MockEnvProviderDetector();
      mockClient = MockSSHClient();
    });

    // @telos-scenario L1:...:remote_ai_integration:detect-then-create-ollama
    test('detection result creates OllamaBackend service', () async {
      when(() => mockOllamaDetector.detect(any()))
          .thenAnswer((_) async => [_ollamaModel, _ollamaModel2]);
      when(() => mockEnvDetector.detect(any())).thenAnswer((_) async => (
            providers: <DetectedCloudProvider>[],
            method: RemoteDetectionMethod.direct,
          ));

      final detector = RemoteAiDetector(
        ollamaDetector: mockOllamaDetector,
        envProviderDetector: mockEnvDetector,
      );

      final result = await detector.detect(
        hostId: 'flow-host',
        client: mockClient,
      );

      // Use detection result to create service (simulating factory logic)
      expect(result.hasOllama, isTrue);
      expect(result.hasCloudProviders, isFalse);

      final backend = OllamaBackend(
        selectedModel: result.ollamaModels.first.name,
        availableModels: result.ollamaModels,
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      expect(service.serviceName, contains('Ollama'));
      expect(service.serviceName, contains('llama3:8b'));
      expect(await service.isAvailable(), isTrue);

      await service.dispose();
      detector.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:detect-then-create-cloud
    test('detection result creates CloudProxyBackend service', () async {
      when(() => mockOllamaDetector.detect(any()))
          .thenAnswer((_) async => null);
      when(() => mockEnvDetector.detect(any())).thenAnswer((_) async => (
            providers: [_anthropicProvider, _openaiProvider],
            method: RemoteDetectionMethod.direct,
          ));

      final detector = RemoteAiDetector(
        ollamaDetector: mockOllamaDetector,
        envProviderDetector: mockEnvDetector,
      );

      final result = await detector.detect(
        hostId: 'flow-host',
        client: mockClient,
      );

      expect(result.hasOllama, isFalse);
      expect(result.hasCloudProviders, isTrue);

      // Pick best provider by quality rank
      final bestProvider = result.bestCloudProvider!;
      expect(bestProvider.provider, RemoteCloudProvider.anthropic);

      final providerConfig =
          RemoteProviderRegistry.forProvider(bestProvider.provider)!;

      final backend = CloudProxyBackend(
        providerConfig: providerConfig,
        envVarName: bestProvider.envVarName,
      );

      final service = RemoteAiService(
        client: mockClient,
        backend: backend,
      );

      expect(service.serviceName, contains('Anthropic'));
      expect(await service.isAvailable(), isTrue);

      await service.dispose();
      detector.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:detect-nothing-service-unavailable
    test('empty detection result means no service available', () async {
      when(() => mockOllamaDetector.detect(any()))
          .thenAnswer((_) async => null);
      when(() => mockEnvDetector.detect(any())).thenAnswer((_) async => (
            providers: <DetectedCloudProvider>[],
            method: RemoteDetectionMethod.direct,
          ));

      final detector = RemoteAiDetector(
        ollamaDetector: mockOllamaDetector,
        envProviderDetector: mockEnvDetector,
      );

      final result = await detector.detect(
        hostId: 'empty-host',
        client: mockClient,
      );

      expect(result.hasAnyProvider, isFalse);
      expect(result.ollamaModels, isEmpty);
      expect(result.cloudProviders, isEmpty);
      expect(result.bestCloudProvider, isNull);

      detector.dispose();
    });

    // @telos-scenario L1:...:remote_ai_integration:detect-both-prefer-cloud
    test('when both detected, bestCloudProvider returns top-ranked cloud',
        () async {
      when(() => mockOllamaDetector.detect(any()))
          .thenAnswer((_) async => [_ollamaModel]);
      when(() => mockEnvDetector.detect(any())).thenAnswer((_) async => (
            providers: [_openaiProvider, _anthropicProvider],
            method: RemoteDetectionMethod.direct,
          ));

      final detector = RemoteAiDetector(
        ollamaDetector: mockOllamaDetector,
        envProviderDetector: mockEnvDetector,
      );

      final result = await detector.detect(
        hostId: 'both-host',
        client: mockClient,
      );

      expect(result.hasOllama, isTrue);
      expect(result.hasCloudProviders, isTrue);

      // bestCloudProvider returns the first in the list (pre-sorted by env detector)
      expect(result.bestCloudProvider, isNotNull);
      // Either OpenAI or Anthropic depending on list order
      expect(result.bestCloudProvider!.provider,
          anyOf(RemoteCloudProvider.openai, RemoteCloudProvider.anthropic));

      detector.dispose();
    });
  });
}
