// @telos-test L1:function:lib/features/ai/data/services:ollama_backend

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/services/ollama_backend.dart';
import 'package:bento/features/ai/data/services/remote_ai_exceptions.dart';
import 'package:bento/features/ai/domain/entities/ai_suggestion.dart';
import 'package:bento/features/ai/domain/entities/ollama_model.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSSHClient extends Mock implements SSHClient {}

class MockSSHSession extends Mock implements SSHSession {}

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

void main() {
  late MockSSHClient client;
  late OllamaBackend backend;

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    client = MockSSHClient();
    backend = OllamaBackend(
      selectedModel: 'llama3:8b',
      availableModels: [
        OllamaModel(name: 'llama3:8b', modifiedAt: DateTime(2024)),
        OllamaModel(name: 'codellama:7b', modifiedAt: DateTime(2024)),
      ],
    );
  });

  group('OllamaBackend', () {
    group('properties', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:is-configured-true
      test('isConfigured returns true when selectedModel is non-empty', () {
        expect(backend.isConfigured, isTrue);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:is-configured-false
      test('isConfigured returns false when selectedModel is empty', () {
        final unconfigured = OllamaBackend(
          selectedModel: '',
          availableModels: [],
        );
        expect(unconfigured.isConfigured, isFalse);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:display-name
      test('displayName returns Ollama (model)', () {
        expect(backend.displayName, 'Ollama (llama3:8b)');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:privacy-description
      test('privacyDescription returns expected string', () {
        expect(
          backend.privacyDescription,
          'Running locally on remote server. No data leaves your infrastructure.',
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:default-port
      test('default port is 11434', () {
        expect(backend.port, 11434);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:custom-port
      test('custom port is respected', () {
        final custom = OllamaBackend(
          selectedModel: 'llama3:8b',
          availableModels: [],
          port: 8080,
        );
        expect(custom.port, 8080);
      });
    });

    group('generateCommand', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:generate-command-success
      test('returns AiSuggestion on successful response', () async {
        final responseJson = _openAiResponse('ls -la\nList all files');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result = await backend.generateCommand(client, 'list files');

        expect(result, isA<AiSuggestion>());
        expect(result.command, 'ls -la');
        expect(result.explanation, 'List all files');
        expect(result.confidence, 0.8);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:generate-command-curl-format
      test('builds correct curl command with port and headers', () async {
        final responseJson = _openAiResponse('ls\nList');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        await backend.generateCommand(client, 'list files');

        final captured = verify(() => client.execute(captureAny())).captured;
        final command = captured.first as String;
        expect(
            command,
            contains(
                'curl -s --max-time 25 localhost:11434/v1/chat/completions'));
        expect(command, contains('-H "Content-Type: application/json"'));
        expect(command, contains("-d '"));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:generate-command-custom-port
      test('uses custom port in curl command', () async {
        final customBackend = OllamaBackend(
          selectedModel: 'llama3:8b',
          availableModels: [],
          port: 8080,
        );
        final responseJson = _openAiResponse('ls\nList');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        await customBackend.generateCommand(client, 'list files');

        final captured = verify(() => client.execute(captureAny())).captured;
        final command = captured.first as String;
        expect(command, contains('localhost:8080'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:generate-command-request-body
      test('includes model, messages, max_tokens, temperature in request body',
          () async {
        final responseJson = _openAiResponse('ls\nList');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        await backend.generateCommand(client, 'list files');

        final captured = verify(() => client.execute(captureAny())).captured;
        final command = captured.first as String;
        // The command contains the JSON body; verify key fields are present
        expect(command, contains('"model":"llama3:8b"'));
        expect(command, contains('"max_tokens":256'));
        expect(command, contains('"temperature":0.3'));
        expect(command, contains('"stream":false'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:generate-command-default-explanation
      test('defaults explanation to "Generated command" when single line',
          () async {
        final responseJson = _openAiResponse('ls -la');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result = await backend.generateCommand(client, 'list files');

        expect(result.command, 'ls -la');
        expect(result.explanation, 'Generated command');
      });
    });

    group('command parsing', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:parse-strips-markdown-code-blocks
      test('strips markdown code blocks from response', () async {
        final responseJson = _openAiResponse('```bash\nls -la\n```');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result = await backend.generateCommand(client, 'list files');

        expect(result.command, 'ls -la');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:parse-strips-dollar-prefix
      test('strips \$ prefix from command', () async {
        final responseJson = _openAiResponse(r'$ ls -la');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result = await backend.generateCommand(client, 'list files');

        expect(result.command, 'ls -la');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:parse-strips-hash-prefix
      test('strips # prefix from command', () async {
        final responseJson = _openAiResponse('# ls -la');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result = await backend.generateCommand(client, 'list files');

        expect(result.command, 'ls -la');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:parse-newline-separator
      test('splits command and explanation on newline separator', () async {
        final responseJson =
            _openAiResponse('docker ps -a\nShow all containers');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result = await backend.generateCommand(client, 'show containers');

        expect(result.command, 'docker ps -a');
        expect(result.explanation, 'Show all containers');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:parse-pipe-in-command
      test('preserves pipe characters in commands', () async {
        // With newline-based parsing, pipes in the command are preserved
        final responseJson = _openAiResponse(
            'grep foo bar | sort\nFilter and sort matching lines');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result = await backend.generateCommand(client, 'search');

        expect(result.command, 'grep foo bar | sort');
        expect(result.explanation, 'Filter and sort matching lines');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:parse-code-block-with-newline
      test('strips code block and parses newline separator', () async {
        final responseJson =
            _openAiResponse('```\nfind . -name "*.dart"\nFind Dart files\n```');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result = await backend.generateCommand(client, 'find dart files');

        expect(result.command, 'find . -name "*.dart"');
        expect(result.explanation, 'Find Dart files');
      });
    });

    group('error handling', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-curl-not-found
      test('throws CurlNotFoundException on exit code 127', () async {
        final session = _createSession(
          stderrData: 'bash: curl: command not found',
          exitCode: 127,
        );
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(isA<CurlNotFoundException>()),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-non-zero-exit
      test('throws RemoteExecutionException on non-zero exit code', () async {
        final session = _createSession(
          stderrData: 'Connection refused',
          exitCode: 7,
        );
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(
            isA<RemoteExecutionException>().having(
              (e) => e.stderr,
              'stderr',
              'Connection refused',
            ),
          ),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-ollama-api-error
      test('throws RemoteApiException on Ollama error response', () async {
        final errorResponse = jsonEncode({'error': 'model not found'});
        final session = _createSession(stdoutData: errorResponse);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(
            isA<RemoteApiException>().having(
              (e) => e.message,
              'message',
              contains('model not found'),
            ),
          ),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-ollama-api-error-map
      test('throws RemoteApiException with message from error map', () async {
        final errorResponse = jsonEncode({
          'error': {'message': 'model "foo" not found'},
        });
        final session = _createSession(stdoutData: errorResponse);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(
            isA<RemoteApiException>().having(
              (e) => e.message,
              'message',
              contains('model "foo" not found'),
            ),
          ),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-empty-choices
      test('throws RemoteParseException on empty choices', () async {
        final emptyResponse = jsonEncode({'choices': []});
        final session = _createSession(stdoutData: emptyResponse);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(isA<RemoteParseException>()),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-null-choices
      test('throws RemoteParseException on null choices', () async {
        final nullResponse = jsonEncode({'choices': null});
        final session = _createSession(stdoutData: nullResponse);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(isA<RemoteParseException>()),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-invalid-json
      test('throws RemoteParseException with rawResponse on invalid JSON',
          () async {
        final session = _createSession(stdoutData: 'not valid json at all');
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(
            isA<RemoteParseException>().having(
              (e) => e.rawResponse,
              'rawResponse',
              contains('not valid json at all'),
            ),
          ),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-invalid-json-truncated
      test('truncates rawResponse to 200 chars on invalid JSON', () async {
        final longGarbage = 'x' * 300;
        final session = _createSession(stdoutData: longGarbage);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(
            isA<RemoteParseException>().having(
              (e) => e.rawResponse!.length,
              'rawResponse length',
              203, // 200 chars + '...'
            ),
          ),
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:error-empty-content
      test('throws RemoteParseException on empty content', () async {
        final emptyContent = jsonEncode({
          'choices': [
            {
              'message': {'content': ''},
            },
          ],
        });
        final session = _createSession(stdoutData: emptyContent);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        expect(
          () => backend.generateCommand(client, 'list files'),
          throwsA(isA<RemoteParseException>()),
        );
      });
    });

    group('generateCommandStream', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-tokens-and-complete
      test('yields AiStreamToken for each delta and AiStreamComplete on DONE',
          () async {
        final chunks = [
          _sseDataLine('ls'),
          _sseDataLine(' -la'),
          'data: [DONE]\n',
        ];
        final session = _createStreamingSession(chunks);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        expect(events, hasLength(3));
        expect(events[0], isA<AiStreamToken>());
        expect((events[0] as AiStreamToken).token, 'ls');
        expect(events[1], isA<AiStreamToken>());
        expect((events[1] as AiStreamToken).token, ' -la');
        expect(events[2], isA<AiStreamComplete>());
        final complete = events[2] as AiStreamComplete;
        expect(complete.suggestion.command, 'ls -la');
        expect(complete.suggestion.confidence, 0.8);
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-uses-sn-flag
      test('uses curl -sN flag for streaming', () async {
        final chunks = ['data: [DONE]\n'];
        final session = _createStreamingSession(chunks);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        // Consume the stream to trigger the execute call
        await backend.generateCommandStream(client, 'list files').toList();

        final captured = verify(() => client.execute(captureAny())).captured;
        final command = captured.first as String;
        expect(command, contains('curl -sN'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-request-body-stream-true
      test('sets stream: true in request body for streaming', () async {
        final chunks = ['data: [DONE]\n'];
        final session = _createStreamingSession(chunks);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        await backend.generateCommandStream(client, 'list files').toList();

        final captured = verify(() => client.execute(captureAny())).captured;
        final command = captured.first as String;
        expect(command, contains('"stream":true'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-end-without-done-with-content
      test(
          'yields AiStreamComplete when stream ends without [DONE] but has content',
          () async {
        final chunks = [
          _sseDataLine('ls -la'),
        ];
        final session = _createStreamingSession(chunks);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        // Should have token + complete
        expect(events.last, isA<AiStreamComplete>());
        final complete = events.last as AiStreamComplete;
        expect(complete.suggestion.command, 'ls -la');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-end-without-done-empty
      test(
          'yields AiStreamError when stream ends without [DONE] and no content',
          () async {
        final session = _createStreamingSession([]);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        expect(events, hasLength(1));
        expect(events[0], isA<AiStreamError>());
        expect(
          (events[0] as AiStreamError).message,
          'No response from Ollama',
        );
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-execute-failure
      test('yields AiStreamError with remote_exec_failed on execute failure',
          () async {
        when(() => client.execute(any()))
            .thenThrow(Exception('SSH connection lost'));

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        expect(events, hasLength(1));
        expect(events[0], isA<AiStreamError>());
        final error = events[0] as AiStreamError;
        expect(error.code, 'remote_exec_failed');
        expect(error.message, contains('Failed to start Ollama streaming'));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-skips-malformed-json
      test('skips malformed JSON chunks without crashing', () async {
        final chunks = [
          'data: not-json\n',
          _sseDataLine('ls'),
          'data: [DONE]\n',
        ];
        final session = _createStreamingSession(chunks);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        // Should have 1 token + 1 complete (malformed chunk skipped)
        final tokens = events.whereType<AiStreamToken>().toList();
        expect(tokens, hasLength(1));
        expect(tokens[0].token, 'ls');
        expect(events.last, isA<AiStreamComplete>());
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-skips-empty-lines
      test('skips empty lines in SSE stream', () async {
        final chunks = [
          '\n\n',
          _sseDataLine('ls'),
          '\n',
          'data: [DONE]\n',
        ];
        final session = _createStreamingSession(chunks);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        final tokens = events.whereType<AiStreamToken>().toList();
        expect(tokens, hasLength(1));
        expect(tokens[0].token, 'ls');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:stream-parses-newline-in-done
      test('parses command\\nexplanation format on stream complete', () async {
        final chunks = [
          _sseDataLine('ls -la'),
          _sseDataLine('\nList all files'),
          'data: [DONE]\n',
        ];
        final session = _createStreamingSession(chunks);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final events =
            await backend.generateCommandStream(client, 'list files').toList();

        final complete = events.whereType<AiStreamComplete>().first;
        expect(complete.suggestion.command, 'ls -la');
        expect(complete.suggestion.explanation, 'List all files');
      });
    });

    group('summarizeOutput', () {
      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:summarize-success
      test('returns content from successful response', () async {
        final responseJson = _openAiResponse('Found 5 files in directory.');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result =
            await backend.summarizeOutput(client, 'ls', 'file1\nfile2');

        expect(result, 'Found 5 files in directory.');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:summarize-truncates-long-output
      test('truncates output longer than 2000 chars', () async {
        final longOutput = 'x' * 3000;
        final responseJson = _openAiResponse('Summary of long output.');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        await backend.summarizeOutput(client, 'ls', longOutput);

        final captured = verify(() => client.execute(captureAny())).captured;
        final command = captured.first as String;
        // The truncated output should be 2000 chars + '...'
        // Verify the full 3000-char output is NOT in the command
        expect(command, isNot(contains('x' * 3000)));
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:summarize-non-zero-exit
      test('returns fallback message on non-zero exit code', () async {
        final session = _createSession(
          stderrData: 'Connection refused',
          exitCode: 1,
        );
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result =
            await backend.summarizeOutput(client, 'ls', 'file1\nfile2');

        expect(result, 'Unable to generate summary.');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:summarize-parse-failure
      test('returns fallback message on parse failure', () async {
        final session = _createSession(stdoutData: 'not json');
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result =
            await backend.summarizeOutput(client, 'ls', 'file1\nfile2');

        expect(result, 'Unable to generate summary.');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:summarize-empty-choices
      test('returns fallback message on empty choices', () async {
        final emptyResponse = jsonEncode({'choices': []});
        final session = _createSession(stdoutData: emptyResponse);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        final result =
            await backend.summarizeOutput(client, 'ls', 'file1\nfile2');

        expect(result, 'Unable to generate summary.');
      });

      // @telos-scenario L1:function:lib/features/ai/data/services:ollama_backend:summarize-does-not-truncate-short
      test('does not truncate output shorter than 2000 chars', () async {
        const shortOutput = 'file1\nfile2\nfile3';
        final responseJson = _openAiResponse('3 files found.');
        final session = _createSession(stdoutData: responseJson);
        when(() => client.execute(any())).thenAnswer((_) async => session);

        await backend.summarizeOutput(client, 'ls', shortOutput);

        final captured = verify(() => client.execute(captureAny())).captured;
        final command = captured.first as String;
        // Short output should be included as-is (no '...' truncation marker)
        expect(command, contains('file1'));
        expect(command, contains('file3'));
      });
    });
  });
}
