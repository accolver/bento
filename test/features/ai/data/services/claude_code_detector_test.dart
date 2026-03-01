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

/// Sentinel echoed by the detector when credentials file is found.
const _sentinel = 'CLAUDE_CODE_FOUND';

/// The detection command used by [ClaudeCodeDetector].
const _detectionCmd =
    'test -d ~/.claude && test -f ~/.claude/.credentials && echo "$_sentinel"';

/// The version command used by [ClaudeCodeDetector].
const _versionCmd = 'claude --version 2>/dev/null';

/// Creates a [MockSSHSession] with the given [stdout] output and [exitCode].
///
/// [stderr] defaults to an empty stream.
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

void main() {
  late MockSSHClient mockClient;
  late ClaudeCodeDetector detector;

  setUp(() {
    mockClient = MockSSHClient();
    detector = const ClaudeCodeDetector();
  });

  group('ClaudeCodeDetector', () {
    // @telos-scenario L1:...:claude_code_detector:detected-with-version
    test('detects when credentials file exists and captures version', () async {
      // Arrange: detection succeeds, version command returns a version
      final detectionSession = _sessionWith(
        stdout: '$_sentinel\n',
        exitCode: 0,
      );
      final versionSession = _sessionWith(
        stdout: '1.0.17\n',
        exitCode: 0,
      );

      var callCount = 0;
      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        callCount++;
        final command = invocation.positionalArguments[0] as String;
        if (command.contains('--version')) {
          return versionSession;
        }
        return detectionSession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isTrue);
      expect(result.version, '1.0.17');
      // Two calls: detection + version
      verify(() => mockClient.execute(any())).called(2);
    });

    // @telos-scenario L1:...:claude_code_detector:detected-without-version
    test('detects but returns null version when CLI not found', () async {
      // Arrange: detection succeeds, version command fails (exit 127 = not found)
      final detectionSession = _sessionWith(
        stdout: '$_sentinel\n',
        exitCode: 0,
      );
      final versionSession = _sessionWith(
        stdout: '',
        exitCode: 127,
      );

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (command.contains('--version')) {
          return versionSession;
        }
        return detectionSession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:not-detected-exit-1
    test('returns not detected when credentials file missing (exit 1)',
        () async {
      // Arrange: test -f fails → exit 1, no sentinel in output
      final session = _sessionWith(
        stdout: '',
        exitCode: 1,
      );

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isFalse);
      expect(result.version, isNull);
      // Only one call — no version check when not detected
      verify(() => mockClient.execute(any())).called(1);
    });

    // @telos-scenario L1:...:claude_code_detector:not-detected-no-sentinel
    test('returns not detected when exit 0 but sentinel missing', () async {
      // Arrange: command exits 0 but stdout doesn't contain sentinel
      final session = _sessionWith(
        stdout: 'some other output\n',
        exitCode: 0,
      );

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isFalse);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:timeout-returns-not-detected
    test('returns not detected on timeout', () async {
      // Arrange: execute times out
      when(() => mockClient.execute(any()))
          .thenThrow(TimeoutException('SSH timed out'));

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isFalse);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:ssh-exception-returns-not-detected
    test('returns not detected on SSH exception', () async {
      // Arrange: execute throws an SSH error
      when(() => mockClient.execute(any()))
          .thenThrow(Exception('SSH connection lost'));

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isFalse);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:version-timeout-still-detected
    test('returns detected with null version when version command times out',
        () async {
      // Arrange: detection succeeds, version command times out
      final detectionSession = _sessionWith(
        stdout: '$_sentinel\n',
        exitCode: 0,
      );

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (command.contains('--version')) {
          throw TimeoutException('version timed out');
        }
        return detectionSession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:version-exception-still-detected
    test('returns detected with null version when version command throws',
        () async {
      // Arrange: detection succeeds, version command throws
      final detectionSession = _sessionWith(
        stdout: '$_sentinel\n',
        exitCode: 0,
      );

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (command.contains('--version')) {
          throw Exception('SSH channel closed');
        }
        return detectionSession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:version-unknown-returns-null
    test('returns null version when CLI outputs "unknown"', () async {
      // Arrange: detection succeeds, version returns "unknown"
      final detectionSession = _sessionWith(
        stdout: '$_sentinel\n',
        exitCode: 0,
      );
      final versionSession = _sessionWith(
        stdout: 'unknown\n',
        exitCode: 0,
      );

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (command.contains('--version')) {
          return versionSession;
        }
        return detectionSession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:version-empty-returns-null
    test('returns null version when CLI outputs empty string', () async {
      // Arrange: detection succeeds, version returns empty
      final detectionSession = _sessionWith(
        stdout: '$_sentinel\n',
        exitCode: 0,
      );
      final versionSession = _sessionWith(
        stdout: '\n',
        exitCode: 0,
      );

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (command.contains('--version')) {
          return versionSession;
        }
        return detectionSession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:not-detected-static-const
    test('notDetected static const has correct values', () {
      expect(ClaudeCodeDetectionResult.notDetected.detected, isFalse);
      expect(ClaudeCodeDetectionResult.notDetected.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:multi-chunk-stdout
    test('handles stdout delivered in multiple chunks', () async {
      // Arrange: detection output arrives in two chunks
      final session = MockSSHSession();
      final chunk1 = Uint8List.fromList(utf8.encode('CLAUDE_'));
      final chunk2 = Uint8List.fromList(utf8.encode('CODE_FOUND\n'));

      when(() => session.stdout).thenAnswer(
        (_) => Stream.fromIterable([chunk1, chunk2]),
      );
      when(() => session.stderr).thenAnswer(
        (_) => Stream.value(Uint8List.fromList(utf8.encode(''))),
      );
      when(() => session.exitCode).thenReturn(0);

      // Version session
      final versionSession = _sessionWith(
        stdout: '1.2.3\n',
        exitCode: 0,
      );

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (command.contains('--version')) {
          return versionSession;
        }
        return session;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.detected, isTrue);
      expect(result.version, '1.2.3');
    });
  });
}
