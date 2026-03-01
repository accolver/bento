// @telos-test L1:function:lib/features/ai/data/services:claude_code_detector

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/services/claude_code_detector.dart';
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

/// Sentinel echoed by the detector when Claude Code CLI is found.
const _sentinel = 'CLAUDE_CODE_FOUND';

/// Auth sentinel echoed when Claude Code has a valid session.
const _authSentinel = 'AUTH_OK';

/// Creates a [MockSSHSession] with the given [stdout] output and [exitCode].
MockSSHSession _sessionWith({
  required String stdout,
  required int exitCode,
}) {
  final session = MockSSHSession();
  when(() => session.stdout).thenAnswer(
    (_) => Stream.value(Uint8List.fromList(utf8.encode(stdout))),
  );
  when(() => session.stderr).thenAnswer(
    (_) => Stream.value(Uint8List.fromList(utf8.encode(''))),
  );
  when(() => session.exitCode).thenReturn(exitCode);
  return session;
}

/// Determines which step a command belongs to.
enum _Step { detection, auth, version }

_Step _classifyCommand(String command) {
  if (command.contains('command -v claude')) return _Step.detection;
  if (command.contains('--print-access-token')) return _Step.auth;
  if (command.contains('--version')) return _Step.version;
  return _Step.detection; // fallback
}

void main() {
  late MockSSHClient mockClient;
  late ClaudeCodeDetector detector;

  setUp(() {
    mockClient = MockSSHClient();
    detector = const ClaudeCodeDetector();
  });

  group('ClaudeCodeDetector', () {
    // @telos-scenario L1:...:claude_code_detector:detected-with-version
    test('detects when CLI exists, auth valid, and captures version', () async {
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final cmd = invocation.positionalArguments[0] as String;
        switch (_classifyCommand(cmd)) {
          case _Step.detection:
            return _sessionWith(stdout: '$_sentinel\n', exitCode: 0);
          case _Step.auth:
            return _sessionWith(stdout: '$_authSentinel\n', exitCode: 0);
          case _Step.version:
            return _sessionWith(stdout: '1.0.17\n', exitCode: 0);
        }
      });

      final result = await detector.detect(mockClient);

      expect(result.detected, isTrue);
      expect(result.version, '1.0.17');
      // Three calls: detection + auth + version
      verify(() => mockClient.execute(any())).called(3);
    });

    // @telos-scenario L1:...:claude_code_detector:detected-without-version
    test('detects but returns null version when version cmd fails', () async {
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final cmd = invocation.positionalArguments[0] as String;
        switch (_classifyCommand(cmd)) {
          case _Step.detection:
            return _sessionWith(stdout: '$_sentinel\n', exitCode: 0);
          case _Step.auth:
            return _sessionWith(stdout: '$_authSentinel\n', exitCode: 0);
          case _Step.version:
            return _sessionWith(stdout: '', exitCode: 127);
        }
      });

      final result = await detector.detect(mockClient);

      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:not-detected-cli-missing
    test('returns not detected when CLI not in PATH', () async {
      final session = _sessionWith(stdout: '', exitCode: 1);
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);

      expect(result.detected, isFalse);
      expect(result.version, isNull);
      // Only one call — no auth/version when CLI missing
      verify(() => mockClient.execute(any())).called(1);
    });

    // @telos-scenario L1:...:claude_code_detector:not-detected-not-authenticated
    test('returns not detected when CLI exists but not authenticated',
        () async {
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final cmd = invocation.positionalArguments[0] as String;
        switch (_classifyCommand(cmd)) {
          case _Step.detection:
            return _sessionWith(stdout: '$_sentinel\n', exitCode: 0);
          case _Step.auth:
            // Auth fails — no valid session
            return _sessionWith(stdout: '', exitCode: 1);
          case _Step.version:
            return _sessionWith(stdout: '', exitCode: 0);
        }
      });

      final result = await detector.detect(mockClient);

      expect(result.detected, isFalse);
      expect(result.version, isNull);
      // Two calls: detection + auth (no version since auth failed)
      verify(() => mockClient.execute(any())).called(2);
    });

    // @telos-scenario L1:...:claude_code_detector:not-detected-no-sentinel
    test('returns not detected when exit 0 but sentinel missing', () async {
      final session = _sessionWith(stdout: 'some other output\n', exitCode: 0);
      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);

      expect(result.detected, isFalse);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:timeout-returns-not-detected
    test('returns not detected on timeout', () async {
      when(() => mockClient.execute(any()))
          .thenThrow(TimeoutException('SSH timed out'));

      final result = await detector.detect(mockClient);

      expect(result.detected, isFalse);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:ssh-exception-returns-not-detected
    test('returns not detected on SSH exception', () async {
      when(() => mockClient.execute(any()))
          .thenThrow(Exception('SSH connection lost'));

      final result = await detector.detect(mockClient);

      expect(result.detected, isFalse);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:version-timeout-still-detected
    test('returns detected with null version when version times out', () async {
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final cmd = invocation.positionalArguments[0] as String;
        switch (_classifyCommand(cmd)) {
          case _Step.detection:
            return _sessionWith(stdout: '$_sentinel\n', exitCode: 0);
          case _Step.auth:
            return _sessionWith(stdout: '$_authSentinel\n', exitCode: 0);
          case _Step.version:
            throw TimeoutException('version timed out');
        }
      });

      final result = await detector.detect(mockClient);

      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:version-exception-still-detected
    test('returns detected with null version when version throws', () async {
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final cmd = invocation.positionalArguments[0] as String;
        switch (_classifyCommand(cmd)) {
          case _Step.detection:
            return _sessionWith(stdout: '$_sentinel\n', exitCode: 0);
          case _Step.auth:
            return _sessionWith(stdout: '$_authSentinel\n', exitCode: 0);
          case _Step.version:
            throw Exception('SSH channel closed');
        }
      });

      final result = await detector.detect(mockClient);

      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:version-unknown-returns-null
    test('returns null version when CLI outputs "unknown"', () async {
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final cmd = invocation.positionalArguments[0] as String;
        switch (_classifyCommand(cmd)) {
          case _Step.detection:
            return _sessionWith(stdout: '$_sentinel\n', exitCode: 0);
          case _Step.auth:
            return _sessionWith(stdout: '$_authSentinel\n', exitCode: 0);
          case _Step.version:
            return _sessionWith(stdout: 'unknown\n', exitCode: 0);
        }
      });

      final result = await detector.detect(mockClient);

      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:version-empty-returns-null
    test('returns null version when CLI outputs empty string', () async {
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final cmd = invocation.positionalArguments[0] as String;
        switch (_classifyCommand(cmd)) {
          case _Step.detection:
            return _sessionWith(stdout: '$_sentinel\n', exitCode: 0);
          case _Step.auth:
            return _sessionWith(stdout: '$_authSentinel\n', exitCode: 0);
          case _Step.version:
            return _sessionWith(stdout: '\n', exitCode: 0);
        }
      });

      final result = await detector.detect(mockClient);

      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:not-detected-static-const
    test('notDetected static const has correct values', () {
      expect(ClaudeCodeDetectionResult.notDetected.detected, isFalse);
      expect(ClaudeCodeDetectionResult.notDetected.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:auth-timeout-returns-not-detected
    test('returns not detected when auth check times out', () async {
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final cmd = invocation.positionalArguments[0] as String;
        switch (_classifyCommand(cmd)) {
          case _Step.detection:
            return _sessionWith(stdout: '$_sentinel\n', exitCode: 0);
          case _Step.auth:
            throw TimeoutException('auth timed out');
          case _Step.version:
            return _sessionWith(stdout: '', exitCode: 0);
        }
      });

      final result = await detector.detect(mockClient);

      // CLI found but auth failed → not detected
      expect(result.detected, isFalse);
    });
  });
}
