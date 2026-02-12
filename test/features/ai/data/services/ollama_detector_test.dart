// @telos-test L1:function:lib/features/ai/data/services:ollama_detector

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/services/ollama_detector.dart';
import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSSHClient extends Mock implements SSHClient {}

class MockSSHSession extends Mock implements SSHSession {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [MockSSHSession] with configurable stdout, stderr, and exitCode.
///
/// - [stdoutData]: String to emit on stdout (empty string → empty stream).
/// - [stderrData]: String to emit on stderr (empty string → empty stream).
/// - [exitCode]: Exit code returned by the session (null if process was killed).
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

/// Builds a valid Ollama `/api/tags` JSON response with the given models.
String _buildTagsJson(List<Map<String, dynamic>> models) {
  return jsonEncode({'models': models});
}

/// A single model entry for the `/api/tags` response.
Map<String, dynamic> _modelEntry({
  String name = 'llama3:8b',
  String digest = 'abc123',
  int size = 4661224676,
  String modifiedAt = '2024-01-15T10:30:00Z',
  Map<String, dynamic>? details,
}) {
  return {
    'name': name,
    'digest': digest,
    'size': size,
    'modified_at': modifiedAt,
    if (details != null) 'details': details,
  };
}

// ---------------------------------------------------------------------------
// Expected curl command
// ---------------------------------------------------------------------------

const _curlCommand = 'curl -s --connect-timeout 2 localhost:11434/api/tags';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockSSHClient mockClient;
  late OllamaDetector detector;

  setUp(() {
    mockClient = MockSSHClient();
    detector = const OllamaDetector();
  });

  group('OllamaDetector', () {
    group('detect', () {
      // @telos-scenario L1:...:ollama_detector:returns-models-when-running
      test('returns list of models when Ollama is running', () async {
        final json = _buildTagsJson([
          _modelEntry(
            name: 'llama3:8b',
            digest: 'abc123',
            size: 4661224676,
            modifiedAt: '2024-01-15T10:30:00Z',
            details: {
              'parameter_size': '8B',
              'quantization_level': 'Q4_0',
            },
          ),
          _modelEntry(
            name: 'codellama:7b',
            digest: 'def456',
            size: 3825820160,
            modifiedAt: '2024-02-20T14:00:00Z',
            details: {
              'parameter_size': '7B',
              'quantization_level': 'Q4_K_M',
            },
          ),
        ]);

        final session = _createSession(stdoutData: json, exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNotNull);
        expect(result, hasLength(2));
        expect(result![0].name, 'llama3:8b');
        expect(result[1].name, 'codellama:7b');
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-on-nonzero-exit
      test('returns null when curl fails (exitCode != 0)', () async {
        final session = _createSession(
          stdoutData: 'curl: (7) Failed to connect',
          stderrData: 'Connection refused',
          exitCode: 7,
        );
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-on-empty-response
      test('returns null when response is empty', () async {
        final session = _createSession(stdoutData: '', exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-on-invalid-json
      test('returns null when response is invalid JSON', () async {
        final session = _createSession(
          stdoutData: 'not valid json {{{',
          exitCode: 0,
        );
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-on-timeout
      test('returns null when timeout occurs', () async {
        // Simulate execute() hanging beyond the 5-second timeout
        when(() => mockClient.execute(_curlCommand)).thenAnswer(
          (_) => Completer<SSHSession>().future, // never completes
        );

        final result = await detector.detect(mockClient);

        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-on-execute-throws
      test('returns null when execute throws', () async {
        when(() => mockClient.execute(_curlCommand))
            .thenThrow(Exception('SSH connection lost'));

        final result = await detector.detect(mockClient);

        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:skips-empty-name-models
      test('skips models with empty names', () async {
        final json = _buildTagsJson([
          _modelEntry(name: 'llama3:8b'),
          _modelEntry(name: ''), // empty name — should be filtered out
          _modelEntry(name: 'codellama:7b'),
        ]);

        final session = _createSession(stdoutData: json, exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNotNull);
        expect(result, hasLength(2));
        expect(result!.map((m) => m.name), ['llama3:8b', 'codellama:7b']);
      });

      // @telos-scenario L1:...:ollama_detector:parses-model-fields
      test('correctly parses all model fields', () async {
        final json = _buildTagsJson([
          _modelEntry(
            name: 'mistral:latest',
            digest: 'sha256deadbeef',
            size: 7365960704,
            modifiedAt: '2024-03-10T08:15:30Z',
            details: {
              'parameter_size': '7B',
              'quantization_level': 'Q5_K_M',
              'family': 'mistral',
            },
          ),
        ]);

        final session = _createSession(stdoutData: json, exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNotNull);
        expect(result, hasLength(1));

        final model = result!.first;
        expect(model.name, 'mistral:latest');
        expect(model.digest, 'sha256deadbeef');
        expect(model.sizeBytes, 7365960704);
        expect(model.modifiedAt, DateTime.utc(2024, 3, 10, 8, 15, 30));
        expect(model.details, isNotNull);
        expect(model.details!['parameter_size'], '7B');
        expect(model.details!['quantization_level'], 'Q5_K_M');
        expect(model.details!['family'], 'mistral');
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-on-null-exit-code
      test('returns null when exitCode is null (process killed)', () async {
        final session = _createSession(stdoutData: '', exitCode: null);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-on-empty-models-list
      test('returns null when models list is empty', () async {
        final json = _buildTagsJson([]); // {"models": []}

        final session = _createSession(stdoutData: json, exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-on-missing-models-key
      test('returns null when JSON has no "models" key', () async {
        final json = jsonEncode({'status': 'ok'}); // no "models" key

        final session = _createSession(stdoutData: json, exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:handles-missing-optional-fields
      test('handles models with missing optional fields', () async {
        // Minimal model: name and modified_at are required by fromJson.
        // The Ollama API always includes modified_at, so this is realistic.
        final json = jsonEncode({
          'models': [
            {'name': 'tiny-model', 'modified_at': '2025-01-01T00:00:00Z'},
          ],
        });

        final session = _createSession(stdoutData: json, exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNotNull);
        expect(result, hasLength(1));

        final model = result!.first;
        expect(model.name, 'tiny-model');
        expect(model.digest, isNull);
        expect(model.sizeBytes, 0);
        expect(model.details, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:handles-chunked-stdout
      test('collects multi-chunk stdout correctly', () async {
        // Simulate stdout arriving in multiple chunks
        final session = MockSSHSession();
        final fullJson = _buildTagsJson([_modelEntry(name: 'llama3:8b')]);
        final midpoint = fullJson.length ~/ 2;
        final chunk1 = fullJson.substring(0, midpoint);
        final chunk2 = fullJson.substring(midpoint);

        when(() => session.stdout).thenAnswer((_) {
          return Stream.fromIterable([
            Uint8List.fromList(utf8.encode(chunk1)),
            Uint8List.fromList(utf8.encode(chunk2)),
          ]);
        });
        when(() => session.stderr)
            .thenAnswer((_) => const Stream<Uint8List>.empty());
        when(() => session.exitCode).thenReturn(0);

        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        expect(result, isNotNull);
        expect(result, hasLength(1));
        expect(result!.first.name, 'llama3:8b');
      });

      // @telos-scenario L1:...:ollama_detector:returns-null-all-models-empty-name
      test('returns null when all models have empty names', () async {
        final json = _buildTagsJson([
          _modelEntry(name: ''),
          _modelEntry(name: ''),
        ]);

        final session = _createSession(stdoutData: json, exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        final result = await detector.detect(mockClient);

        // All models filtered out → empty list → returns null
        expect(result, isNull);
      });

      // @telos-scenario L1:...:ollama_detector:verifies-curl-command
      test('executes the correct curl command', () async {
        final json = _buildTagsJson([_modelEntry()]);
        final session = _createSession(stdoutData: json, exitCode: 0);
        when(() => mockClient.execute(_curlCommand))
            .thenAnswer((_) async => session);

        await detector.detect(mockClient);

        verify(
          () => mockClient
              .execute('curl -s --connect-timeout 2 localhost:11434/api/tags'),
        ).called(1);
      });
    });
  });
}
