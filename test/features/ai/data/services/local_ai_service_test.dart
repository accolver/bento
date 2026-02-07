// @telos-test L1:function:lib/features/ai/data/services:local_ai_service
import 'dart:io';

import 'package:bento/features/ai/data/services/local_ai_service.dart';
import 'package:bento/features/ai/domain/entities/ai_privacy_mode.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalAiService', () {
    late Directory tempDir;
    late File testModelFile;

    setUp(() async {
      // Create a temp directory with a fake model file
      tempDir = await Directory.systemTemp.createTemp('local_ai_test_');
      testModelFile = File('${tempDir.path}/test-model.gguf');
      await testModelFile.writeAsString('fake gguf content');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    LocalAiService createService({String? modelPath}) {
      return LocalAiService(
        modelPath: modelPath ?? testModelFile.path,
        contextSize: 2048,
        maxTokens: 256,
        temperature: 0.3,
        nThreads: 4,
        useGpu: true,
      );
    }

    // @telos-scenario L1:function:lib/features/ai/data/services:local_ai_service:service-name
    group('serviceName', () {
      test('returns "Local" with model name extracted from path', () {
        final service = createService(
          modelPath: '/path/to/tinyllama-q4_k_m.gguf',
        );

        expect(service.serviceName, equals('Local (Tinyllama)'));
      });

      test('handles model names without quantization suffix', () {
        final service = createService(
          modelPath: '/path/to/phi3-mini.gguf',
        );

        expect(service.serviceName, equals('Local (Phi3-mini)'));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:local_ai_service:privacy-mode
    group('privacyMode', () {
      test('returns AiPrivacyMode.local', () {
        final service = createService();

        expect(service.privacyMode, equals(AiPrivacyMode.local));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:local_ai_service:is-available
    group('isAvailable', () {
      test('returns false when model file does not exist', () async {
        final service = createService(
          modelPath: '/nonexistent/path/model.gguf',
        );

        expect(await service.isAvailable(), isFalse);
      });

      test('returns true when model file exists', () async {
        final service = createService();

        expect(await service.isAvailable(), isTrue);
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:local_ai_service:generate-command
    group('generateCommand', () {
      // Note: Tests run on macOS/Linux, so these test the fallback path
      // On Android, the actual LLM inference would be used instead
      // Since we removed pattern matching, non-Android returns a fallback message

      test('returns fallback suggestion on non-Android platforms', () async {
        final service = createService();
        final suggestion = await service.generateCommand('list all files');

        // On non-Android platforms, returns fallback message since LLM not available
        expect(suggestion.confidence, equals(0.0));
        expect(suggestion.explanation, contains('model'));
      });

      test('throws AiServiceException when model file not found', () async {
        final service = createService(
          modelPath: '/nonexistent/model.gguf',
        );

        expect(
          () => service.generateCommand('list files'),
          throwsA(isA<AiServiceException>().having(
            (e) => e.code,
            'code',
            'model_not_found',
          )),
        );
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:local_ai_service:streaming
    group('generateCommandStream', () {
      test('yields error on non-Android platforms', () async {
        final service = createService();
        final events =
            await service.generateCommandStream('list files').toList();

        // On non-Android platforms, yields an error since LLM not available
        expect(events.length, equals(1));
        expect(events.first, isA<AiStreamError>());

        final error = events.first as AiStreamError;
        expect(error.message, contains('not available'));
      });

      test('yields error event when model file not found', () async {
        final service = createService(
          modelPath: '/nonexistent/model.gguf',
        );

        final events =
            await service.generateCommandStream('list files').toList();

        expect(events.length, equals(1));
        expect(events[0], isA<AiStreamError>());

        final error = events[0] as AiStreamError;
        expect(error.code, equals('model_not_found'));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:local_ai_service:dispose
    group('dispose', () {
      test('does not throw', () async {
        final service = createService();

        // Should not throw
        await expectLater(service.dispose(), completes);
      });

      test('can be called multiple times safely', () async {
        final service = createService();

        await expectLater(service.dispose(), completes);
        await expectLater(service.dispose(), completes);
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:local_ai_service:model-name-extraction
    group('model name extraction', () {
      test('extracts name from path with q4_k_m suffix', () {
        final service = createService(
          modelPath: '/path/to/llama-3.2-1b-instruct-q4_k_m.gguf',
        );

        // Should extract clean name
        expect(service.serviceName, contains('Llama'));
      });

      test('extracts name from path with q8_0 suffix', () {
        final service = createService(
          modelPath: '/path/to/phi3-q8_0.gguf',
        );

        expect(service.serviceName, contains('Phi3'));
      });

      test('extracts name from path with q4_0 suffix', () {
        final service = createService(
          modelPath: '/path/to/gemma-2-2b-q4_0.gguf',
        );

        expect(service.serviceName, contains('Gemma'));
      });

      test('extracts name from path with q4_k_s suffix', () {
        final service = createService(
          modelPath: '/path/to/qwen2-0.5b-q4_k_s.gguf',
        );

        expect(service.serviceName, contains('Qwen2'));
      });

      test('handles model path without quantization suffix', () {
        final service = createService(
          modelPath: '/path/to/custom-model.gguf',
        );

        expect(service.serviceName, equals('Local (Custom-model)'));
      });

      test('handles empty filename gracefully', () {
        final service = createService(
          modelPath: '/path/to/.gguf',
        );

        expect(service.serviceName, equals('Local (Local Model)'));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:local_ai_service:configuration
    group('configuration', () {
      test('respects contextSize parameter', () {
        final service = LocalAiService(
          modelPath: testModelFile.path,
          contextSize: 4096,
        );

        expect(service.contextSize, equals(4096));
      });

      test('respects maxTokens parameter', () {
        final service = LocalAiService(
          modelPath: testModelFile.path,
          maxTokens: 512,
        );

        expect(service.maxTokens, equals(512));
      });

      test('respects temperature parameter', () {
        final service = LocalAiService(
          modelPath: testModelFile.path,
          temperature: 0.7,
        );

        expect(service.temperature, equals(0.7));
      });

      test('respects nThreads parameter', () {
        final service = LocalAiService(
          modelPath: testModelFile.path,
          nThreads: 8,
        );

        expect(service.nThreads, equals(8));
      });

      test('respects useGpu parameter', () {
        final service = LocalAiService(
          modelPath: testModelFile.path,
          useGpu: false,
        );

        expect(service.useGpu, isFalse);
      });

      test('uses sensible defaults', () {
        final service = LocalAiService(modelPath: testModelFile.path);

        expect(service.contextSize, equals(2048));
        expect(service.maxTokens, equals(64)); // Reduced for speed
        expect(service.temperature, equals(0.1)); // Lower for determinism
        expect(service.nThreads, equals(4));
        expect(service.useGpu, isTrue);
      });
    });
  });
}
