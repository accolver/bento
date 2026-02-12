// @telos-test L1:function:lib/features/ai/data/services:remote_ai_service

import 'package:bento/features/ai/data/services/remote_ai_exceptions.dart';
import 'package:bento/features/ai/data/services/remote_ai_service.dart';
import 'package:bento/features/ai/data/services/remote_backend.dart';
import 'package:bento/features/ai/domain/entities/ai_privacy_mode.dart';
import 'package:bento/features/ai/domain/entities/ai_suggestion.dart';
import 'package:bento/features/ai/domain/services/ai_service.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSSHClient extends Mock implements SSHClient {}

class MockRemoteBackend extends Mock implements RemoteBackend {}

void main() {
  late MockSSHClient mockClient;
  late MockRemoteBackend mockBackend;
  late RemoteAiService service;

  setUp(() {
    mockClient = MockSSHClient();
    mockBackend = MockRemoteBackend();

    when(() => mockBackend.isConfigured).thenReturn(true);
    when(() => mockBackend.displayName).thenReturn('Test Backend');
    when(() => mockBackend.privacyDescription).thenReturn('Test privacy');

    service = RemoteAiService(
      client: mockClient,
      backend: mockBackend,
    );
  });

  group('RemoteAiService', () {
    // @telos-scenario L1:...:remote_ai_service:privacy-mode
    test('privacyMode returns remote', () {
      expect(service.privacyMode, AiPrivacyMode.remote);
    });

    // @telos-scenario L1:...:remote_ai_service:service-name
    test('serviceName includes backend display name', () {
      expect(service.serviceName, 'Remote (Test Backend)');
    });

    // @telos-scenario L1:...:remote_ai_service:is-connected-initially
    test('isConnected is true initially', () {
      expect(service.isConnected, true);
    });

    // @telos-scenario L1:...:remote_ai_service:is-available-when-connected
    test('isAvailable returns true when connected and configured', () async {
      expect(await service.isAvailable(), true);
    });

    // @telos-scenario L1:...:remote_ai_service:delegates-generate-command
    test('generateCommand delegates to backend', () async {
      final suggestion = AiSuggestion(
        command: 'ls -la',
        explanation: 'List files',
        confidence: 0.8,
      );
      when(() => mockBackend.generateCommand(mockClient, 'list files'))
          .thenAnswer((_) async => suggestion);

      final result = await service.generateCommand('list files');
      expect(result, suggestion);
      verify(() => mockBackend.generateCommand(mockClient, 'list files'))
          .called(1);
    });

    // @telos-scenario L1:...:remote_ai_service:delegates-summarize-output
    test('summarizeOutput delegates to backend', () async {
      when(() => mockBackend.summarizeOutput(mockClient, 'ls', 'file1\nfile2'))
          .thenAnswer((_) async => '2 files found');

      final result = await service.summarizeOutput('ls', 'file1\nfile2');
      expect(result, '2 files found');
    });

    group('lifecycle', () {
      // @telos-scenario L1:...:remote_ai_service:disconnect-marks-unavailable
      test('onDisconnected marks service unavailable', () async {
        service.onDisconnected();
        expect(service.isConnected, false);
        expect(await service.isAvailable(), false);
      });

      // @telos-scenario L1:...:remote_ai_service:disconnect-throws-on-generate
      test('generateCommand throws when disconnected', () async {
        service.onDisconnected();
        expect(
          () => service.generateCommand('test'),
          throwsA(isA<RemoteDisconnectedException>()),
        );
      });

      // @telos-scenario L1:...:remote_ai_service:reconnect-restores
      test('onReconnected restores availability', () async {
        service.onDisconnected();
        expect(service.isConnected, false);

        final newClient = MockSSHClient();
        service.onReconnected(newClient);
        expect(service.isConnected, true);
        expect(await service.isAvailable(), true);
      });

      // @telos-scenario L1:...:remote_ai_service:dispose-marks-unavailable
      test('dispose marks service unavailable', () async {
        await service.dispose();
        expect(service.isConnected, false);
        expect(await service.isAvailable(), false);
      });

      // @telos-scenario L1:...:remote_ai_service:dispose-throws-on-generate
      test('generateCommand throws after dispose', () async {
        await service.dispose();
        expect(
          () => service.generateCommand('test'),
          throwsA(isA<AiServiceException>()),
        );
      });
    });

    group('backend switching', () {
      // @telos-scenario L1:...:remote_ai_service:switch-backend
      test('switchBackend updates active backend', () {
        final newBackend = MockRemoteBackend();
        when(() => newBackend.displayName).thenReturn('New Backend');
        when(() => newBackend.isConfigured).thenReturn(true);

        service.switchBackend(newBackend);
        expect(service.backend, newBackend);
        expect(service.serviceName, 'Remote (New Backend)');
      });
    });

    group('streaming', () {
      // @telos-scenario L1:...:remote_ai_service:stream-delegates-to-backend
      test('generateCommandStream delegates to backend', () async {
        final suggestion = AiSuggestion(
          command: 'ls',
          explanation: 'List',
          confidence: 0.8,
        );
        when(() => mockBackend.generateCommandStream(mockClient, 'list files'))
            .thenAnswer((_) => Stream.fromIterable([
                  const AiStreamToken('ls'),
                  AiStreamComplete(suggestion),
                ]));

        final events =
            await service.generateCommandStream('list files').toList();
        expect(events, hasLength(2));
        expect(events[0], isA<AiStreamToken>());
        expect(events[1], isA<AiStreamComplete>());
      });

      // @telos-scenario L1:...:remote_ai_service:stream-error-when-disconnected
      test('generateCommandStream yields error when disconnected', () async {
        service.onDisconnected();
        final events = await service.generateCommandStream('test').toList();
        expect(events, hasLength(1));
        expect(events[0], isA<AiStreamError>());
      });
    });

    group('unconfigured backend', () {
      // @telos-scenario L1:...:remote_ai_service:unconfigured-not-available
      test('isAvailable returns false when backend not configured', () async {
        when(() => mockBackend.isConfigured).thenReturn(false);
        expect(await service.isAvailable(), false);
      });

      // @telos-scenario L1:...:remote_ai_service:unconfigured-throws
      test('generateCommand throws when backend not configured', () async {
        when(() => mockBackend.isConfigured).thenReturn(false);
        expect(
          () => service.generateCommand('test'),
          throwsA(isA<AiServiceException>()),
        );
      });
    });
  });
}
