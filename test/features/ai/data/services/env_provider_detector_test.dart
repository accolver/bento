// @telos-test L1:function:lib/features/ai/data/services:env_provider_detector

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/services/env_provider_detector.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_detection.dart';
import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
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

/// Sentinel appended by the detector to mark command completion.
const _sentinel = '---ENV_CHECK_DONE---';

/// Creates a [MockSSHSession] whose [stdout] emits [output] as a single chunk.
MockSSHSession _sessionWithOutput(String output) {
  final session = MockSSHSession();
  when(() => session.stdout).thenAnswer(
    (_) => Stream.value(Uint8List.fromList(utf8.encode(output))),
  );
  return session;
}

/// Builds the expected output for a set of detected env var names,
/// including the sentinel.
String _buildOutput(List<String> envVarNames) {
  final buffer = StringBuffer();
  for (final name in envVarNames) {
    buffer.writeln(name);
  }
  buffer.writeln(_sentinel);
  return buffer.toString();
}

/// Returns `true` if [command] is a direct detection command (not wrapped
/// in a login shell).
bool _isDirect(String command) =>
    !command.startsWith('bash ') && !command.startsWith('zsh ');

/// Returns `true` if [command] is a bash login shell fallback.
bool _isBashLogin(String command) => command.startsWith("bash -l -c '");

/// Returns `true` if [command] is a zsh login shell fallback.
bool _isZshLogin(String command) => command.startsWith("zsh -l -c '");

/// Returns `true` if [command] is a bash interactive login shell fallback.
bool _isBashInteractiveLogin(String command) =>
    command.startsWith("bash -li -c '");

/// Returns `true` if [command] is a zsh interactive login shell fallback.
bool _isZshInteractiveLogin(String command) =>
    command.startsWith("zsh -li -c '");

void main() {
  late MockSSHClient mockClient;
  late EnvProviderDetector detector;

  setUp(() {
    mockClient = MockSSHClient();
    detector = const EnvProviderDetector();
  });

  group('EnvProviderDetector', () {
    // @telos-scenario L1:...:env_provider_detector:direct-detection
    test('returns detected providers when env vars found via direct command',
        () async {
      // Arrange: direct command finds Anthropic + OpenAI
      final output = _buildOutput(['ANTHROPIC_API_KEY', 'OPENAI_API_KEY']);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, hasLength(2));
      expect(result.method, RemoteDetectionMethod.direct);

      expect(result.providers[0].provider, RemoteCloudProvider.anthropic);
      expect(result.providers[0].envVarName, 'ANTHROPIC_API_KEY');

      expect(result.providers[1].provider, RemoteCloudProvider.openai);
      expect(result.providers[1].envVarName, 'OPENAI_API_KEY');

      // Should only call execute once (direct succeeded)
      verify(() => mockClient.execute(any())).called(1);
    });

    // @telos-scenario L1:...:env_provider_detector:empty-when-no-vars
    test('returns empty list when no env vars are found', () async {
      // Arrange: all five strategies return only the sentinel
      final emptyOutput = _buildOutput([]);
      final session = _sessionWithOutput(emptyOutput);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, isEmpty);
      expect(result.method, RemoteDetectionMethod.direct);

      // Called 5 times: direct, bash -l, zsh -l, bash -li, zsh -li
      verify(() => mockClient.execute(any())).called(5);
    });

    // @telos-scenario L1:...:env_provider_detector:fallback-bash-login
    test('falls back to bash login shell when direct finds nothing', () async {
      // Arrange: direct returns empty, bash login finds providers
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final bashOutput = _buildOutput(['OPENAI_API_KEY']);
      final bashSession = _sessionWithOutput(bashOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isBashLogin(command)) {
          return bashSession;
        }
        return emptySession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, hasLength(1));
      expect(result.providers[0].provider, RemoteCloudProvider.openai);
      expect(result.method, RemoteDetectionMethod.bashLogin);

      // Called 2 times: direct (empty), bash -l (found)
      verify(() => mockClient.execute(any())).called(2);
    });

    // @telos-scenario L1:...:env_provider_detector:fallback-zsh-login
    test('falls back to zsh login shell when bash finds nothing', () async {
      // Arrange: direct and bash return empty, zsh finds providers
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final zshOutput = _buildOutput(['GROQ_API_KEY']);
      final zshSession = _sessionWithOutput(zshOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isZshLogin(command)) {
          return zshSession;
        }
        return emptySession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, hasLength(1));
      expect(result.providers[0].provider, RemoteCloudProvider.groq);
      expect(result.method, RemoteDetectionMethod.zshLogin);

      // Called 3 times: direct (empty), bash -l (empty), zsh -l (found)
      verify(() => mockClient.execute(any())).called(3);
    });

    // @telos-scenario L1:...:env_provider_detector:fallback-bash-interactive-login
    test(
        'falls back to bash interactive login when login-only shells find nothing',
        () async {
      // Arrange: direct, bash -l, zsh -l all return empty;
      // bash -li finds providers (e.g., vars set in ~/.bashrc)
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final bashInteractiveOutput = _buildOutput(['OPENAI_API_KEY']);
      final bashInteractiveSession = _sessionWithOutput(bashInteractiveOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isBashInteractiveLogin(command)) {
          return bashInteractiveSession;
        }
        return emptySession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, hasLength(1));
      expect(result.providers[0].provider, RemoteCloudProvider.openai);
      expect(result.method, RemoteDetectionMethod.bashInteractiveLogin);

      // Called 4 times: direct, bash -l, zsh -l, bash -li (found)
      verify(() => mockClient.execute(any())).called(4);
    });

    // @telos-scenario L1:...:env_provider_detector:fallback-zsh-interactive-login
    test(
        'falls back to zsh interactive login when all other strategies find nothing',
        () async {
      // Arrange: direct, bash -l, zsh -l, bash -li all return empty;
      // zsh -li finds providers (e.g., vars set in ~/.zshrc on macOS)
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final zshInteractiveOutput = _buildOutput(['ANTHROPIC_API_KEY']);
      final zshInteractiveSession = _sessionWithOutput(zshInteractiveOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isZshInteractiveLogin(command)) {
          return zshInteractiveSession;
        }
        return emptySession;
      });

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, hasLength(1));
      expect(result.providers[0].provider, RemoteCloudProvider.anthropic);
      expect(result.method, RemoteDetectionMethod.zshInteractiveLogin);

      // Called 5 times: direct, bash -l, zsh -l, bash -li, zsh -li (found)
      verify(() => mockClient.execute(any())).called(5);
    });

    // @telos-scenario L1:...:env_provider_detector:all-strategies-fail
    test('returns empty when all five strategies fail', () async {
      // Arrange: all strategies return empty
      final emptyOutput = _buildOutput([]);
      final session = _sessionWithOutput(emptyOutput);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, isEmpty);
      expect(result.method, RemoteDetectionMethod.direct);
      verify(() => mockClient.execute(any())).called(5);
    });

    // @telos-scenario L1:...:env_provider_detector:deduplicates-same-provider
    test('deduplicates — first env var per provider wins', () async {
      // Arrange: both GOOGLE_API_KEY and GEMINI_API_KEY are set
      // Both map to RemoteCloudProvider.google — only the first should appear
      final output = _buildOutput(['GOOGLE_API_KEY', 'GEMINI_API_KEY']);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      final googleProviders = result.providers
          .where((p) => p.provider == RemoteCloudProvider.google)
          .toList();
      expect(googleProviders, hasLength(1));
      expect(googleProviders[0].envVarName, 'GOOGLE_API_KEY');
    });

    // @telos-scenario L1:...:env_provider_detector:dedup-anthropic-vars
    test(
        'deduplicates Anthropic — ANTHROPIC_API_KEY wins over CLAUDE_CODE_OAUTH_TOKEN',
        () async {
      // Both map to RemoteCloudProvider.anthropic
      final output = _buildOutput([
        'ANTHROPIC_API_KEY',
        'CLAUDE_CODE_OAUTH_TOKEN',
      ]);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      final anthropicProviders = result.providers
          .where((p) => p.provider == RemoteCloudProvider.anthropic)
          .toList();
      expect(anthropicProviders, hasLength(1));
      expect(anthropicProviders[0].envVarName, 'ANTHROPIC_API_KEY');
    });

    // @telos-scenario L1:...:env_provider_detector:sorted-by-quality-rank
    test('results are sorted by qualityRank (Anthropic rank 1 first)',
        () async {
      // Arrange: providers detected in reverse quality order
      final output = _buildOutput([
        'COHERE_API_KEY', // rank 11
        'GROQ_API_KEY', // rank 4
        'ANTHROPIC_API_KEY', // rank 1
        'OPENAI_API_KEY', // rank 2
      ]);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, hasLength(4));
      expect(result.providers[0].provider, RemoteCloudProvider.anthropic);
      expect(result.providers[0].qualityRank, 1);
      expect(result.providers[1].provider, RemoteCloudProvider.openai);
      expect(result.providers[1].qualityRank, 2);
      expect(result.providers[2].provider, RemoteCloudProvider.groq);
      expect(result.providers[2].qualityRank, 4);
      expect(result.providers[3].provider, RemoteCloudProvider.cohere);
      expect(result.providers[3].qualityRank, 11);
    });

    // @telos-scenario L1:...:env_provider_detector:correct-detection-method-direct
    test('returns RemoteDetectionMethod.direct when direct succeeds', () async {
      final output = _buildOutput(['ANTHROPIC_API_KEY']);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);
      expect(result.method, RemoteDetectionMethod.direct);
    });

    // @telos-scenario L1:...:env_provider_detector:correct-detection-method-bash
    test('returns RemoteDetectionMethod.bashLogin when bash fallback succeeds',
        () async {
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final bashOutput = _buildOutput(['MISTRAL_API_KEY']);
      final bashSession = _sessionWithOutput(bashOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isBashLogin(command)) return bashSession;
        return emptySession;
      });

      final result = await detector.detect(mockClient);
      expect(result.method, RemoteDetectionMethod.bashLogin);
    });

    // @telos-scenario L1:...:env_provider_detector:correct-detection-method-zsh
    test('returns RemoteDetectionMethod.zshLogin when zsh fallback succeeds',
        () async {
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final zshOutput = _buildOutput(['XAI_API_KEY']);
      final zshSession = _sessionWithOutput(zshOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isZshLogin(command)) return zshSession;
        return emptySession;
      });

      final result = await detector.detect(mockClient);
      expect(result.method, RemoteDetectionMethod.zshLogin);
    });

    // @telos-scenario L1:...:env_provider_detector:correct-detection-method-bash-interactive
    test(
        'returns RemoteDetectionMethod.bashInteractiveLogin when bash -li succeeds',
        () async {
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final bashInteractiveOutput = _buildOutput(['DEEPSEEK_API_KEY']);
      final bashInteractiveSession = _sessionWithOutput(bashInteractiveOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isBashInteractiveLogin(command)) return bashInteractiveSession;
        return emptySession;
      });

      final result = await detector.detect(mockClient);
      expect(result.method, RemoteDetectionMethod.bashInteractiveLogin);
    });

    // @telos-scenario L1:...:env_provider_detector:correct-detection-method-zsh-interactive
    test(
        'returns RemoteDetectionMethod.zshInteractiveLogin when zsh -li succeeds',
        () async {
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final zshInteractiveOutput = _buildOutput(['FIREWORKS_API_KEY']);
      final zshInteractiveSession = _sessionWithOutput(zshInteractiveOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isZshInteractiveLogin(command)) return zshInteractiveSession;
        return emptySession;
      });

      final result = await detector.detect(mockClient);
      expect(result.method, RemoteDetectionMethod.zshInteractiveLogin);
    });

    // @telos-scenario L1:...:env_provider_detector:timeout-returns-empty
    test('handles timeout gracefully and returns empty', () async {
      // Arrange: all execute calls time out
      when(() => mockClient.execute(any()))
          .thenThrow(TimeoutException('SSH timed out'));

      // Act
      final result = await detector.detect(mockClient);

      // Assert
      expect(result.providers, isEmpty);
      expect(result.method, RemoteDetectionMethod.direct);
    });

    // @telos-scenario L1:...:env_provider_detector:missing-sentinel-returns-empty
    test('returns empty when sentinel is missing from output', () async {
      // Arrange: output has env var names but no sentinel
      const outputWithoutSentinel = 'ANTHROPIC_API_KEY\nOPENAI_API_KEY\n';
      final session = _sessionWithOutput(outputWithoutSentinel);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      // Act
      final result = await detector.detect(mockClient);

      // Assert — all five strategies see missing sentinel → empty
      expect(result.providers, isEmpty);
      expect(result.method, RemoteDetectionMethod.direct);
      verify(() => mockClient.execute(any())).called(5);
    });

    // @telos-scenario L1:...:env_provider_detector:single-provider
    test('detects a single provider correctly', () async {
      final output = _buildOutput(['OPENROUTER_API_KEY']);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);

      expect(result.providers, hasLength(1));
      expect(result.providers[0].provider, RemoteCloudProvider.openRouter);
      expect(result.providers[0].envVarName, 'OPENROUTER_API_KEY');
      expect(result.providers[0].displayName, 'OpenRouter');
      expect(result.providers[0].qualityRank, 3);
    });

    // @telos-scenario L1:...:env_provider_detector:all-providers-detected
    test('detects all 11 providers when all env vars are set', () async {
      // Use one env var per provider (the first/preferred one)
      final output = _buildOutput([
        'ANTHROPIC_API_KEY',
        'OPENAI_API_KEY',
        'OPENROUTER_API_KEY',
        'GROQ_API_KEY',
        'GOOGLE_API_KEY',
        'MISTRAL_API_KEY',
        'XAI_API_KEY',
        'DEEPSEEK_API_KEY',
        'FIREWORKS_API_KEY',
        'TOGETHER_API_KEY',
        'COHERE_API_KEY',
      ]);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);

      expect(result.providers, hasLength(11));
      // Verify sorted by quality rank
      for (var i = 0; i < result.providers.length - 1; i++) {
        expect(
          result.providers[i].qualityRank,
          lessThanOrEqualTo(result.providers[i + 1].qualityRank),
        );
      }
    });

    // @telos-scenario L1:...:env_provider_detector:unknown-var-ignored
    test('ignores unknown environment variable names in output', () async {
      final output = _buildOutput([
        'ANTHROPIC_API_KEY',
        'SOME_RANDOM_VAR', // not in registry
        'MY_CUSTOM_KEY', // not in registry
        'OPENAI_API_KEY',
      ]);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);

      expect(result.providers, hasLength(2));
      expect(result.providers[0].provider, RemoteCloudProvider.anthropic);
      expect(result.providers[1].provider, RemoteCloudProvider.openai);
    });

    // @telos-scenario L1:...:env_provider_detector:handles-ssh-exception
    test('handles SSH exceptions gracefully and returns empty', () async {
      when(() => mockClient.execute(any()))
          .thenThrow(Exception('SSH connection lost'));

      final result = await detector.detect(mockClient);

      expect(result.providers, isEmpty);
      expect(result.method, RemoteDetectionMethod.direct);
    });

    // @telos-scenario L1:...:env_provider_detector:noisy-output-with-sentinel
    test('handles noisy output with blank lines and whitespace', () async {
      // Simulate output with extra blank lines and whitespace
      const noisyOutput = '''

  ANTHROPIC_API_KEY
  
  OPENAI_API_KEY  

---ENV_CHECK_DONE---

''';
      final session = _sessionWithOutput(noisyOutput);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);

      expect(result.providers, hasLength(2));
      expect(result.providers[0].provider, RemoteCloudProvider.anthropic);
      expect(result.providers[1].provider, RemoteCloudProvider.openai);
    });

    // @telos-scenario L1:...:env_provider_detector:provider-metadata-correct
    test('detected providers carry correct metadata from registry', () async {
      final output = _buildOutput(['ANTHROPIC_API_KEY']);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);

      expect(result.providers, hasLength(1));
      final provider = result.providers[0];
      expect(provider.provider, RemoteCloudProvider.anthropic);
      expect(provider.envVarName, 'ANTHROPIC_API_KEY');
      expect(provider.displayName, 'Claude (Anthropic)');
      expect(provider.defaultModel, 'claude-sonnet-4-20250514');
      expect(provider.qualityRank, 1);
    });

    // @telos-scenario L1:...:env_provider_detector:direct-success-skips-fallbacks
    test('does not attempt fallback shells when direct detection succeeds',
        () async {
      final output = _buildOutput(['ANTHROPIC_API_KEY']);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      await detector.detect(mockClient);

      // Only 1 call — no bash -l or zsh -l attempted
      verify(() => mockClient.execute(any())).called(1);
    });

    // @telos-scenario L1:...:env_provider_detector:bash-success-skips-zsh
    test('does not attempt zsh fallback when bash login succeeds', () async {
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final bashOutput = _buildOutput(['OPENAI_API_KEY']);
      final bashSession = _sessionWithOutput(bashOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isBashLogin(command)) return bashSession;
        return emptySession;
      });

      await detector.detect(mockClient);

      // 2 calls: direct (empty) + bash -l (found) — no zsh
      verify(() => mockClient.execute(any())).called(2);
    });

    // @telos-scenario L1:...:env_provider_detector:bash-interactive-success-skips-zsh-interactive
    test('does not attempt zsh -li when bash -li succeeds', () async {
      final emptyOutput = _buildOutput([]);
      final emptySession = _sessionWithOutput(emptyOutput);

      final bashInteractiveOutput = _buildOutput(['GROQ_API_KEY']);
      final bashInteractiveSession = _sessionWithOutput(bashInteractiveOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        final command = invocation.positionalArguments[0] as String;
        if (_isBashInteractiveLogin(command)) return bashInteractiveSession;
        return emptySession;
      });

      await detector.detect(mockClient);

      // 4 calls: direct, bash -l, zsh -l, bash -li (found) — no zsh -li
      verify(() => mockClient.execute(any())).called(4);
    });

    // @telos-scenario L1:...:env_provider_detector:direct-timeout-tries-bash
    test('falls back to bash when direct command times out', () async {
      var callCount = 0;

      final bashOutput = _buildOutput(['GROQ_API_KEY']);
      final bashSession = _sessionWithOutput(bashOutput);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        callCount++;
        final command = invocation.positionalArguments[0] as String;
        if (_isDirect(command)) {
          throw TimeoutException('timed out');
        }
        if (_isBashLogin(command)) {
          return bashSession;
        }
        throw TimeoutException('timed out');
      });

      final result = await detector.detect(mockClient);

      expect(result.providers, hasLength(1));
      expect(result.providers[0].provider, RemoteCloudProvider.groq);
      expect(result.method, RemoteDetectionMethod.bashLogin);
    });

    // @telos-scenario L1:...:env_provider_detector:command-structure-direct
    test('direct command does not contain shell wrapper', () async {
      String? capturedCommand;
      final output = _buildOutput(['ANTHROPIC_API_KEY']);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        capturedCommand ??= invocation.positionalArguments[0] as String;
        return session;
      });

      await detector.detect(mockClient);

      expect(capturedCommand, isNotNull);
      expect(capturedCommand, isNot(startsWith('bash ')));
      expect(capturedCommand, isNot(startsWith('zsh ')));
      expect(capturedCommand, contains('test -n'));
      expect(capturedCommand, contains(_sentinel));
    });

    // @telos-scenario L1:...:env_provider_detector:command-checks-all-vars
    test('detection command checks all registered env var names', () async {
      String? capturedCommand;
      final output = _buildOutput([]);
      final session = _sessionWithOutput(output);

      when(() => mockClient.execute(any())).thenAnswer((invocation) async {
        capturedCommand ??= invocation.positionalArguments[0] as String;
        return session;
      });

      await detector.detect(mockClient);

      // Verify all known env vars appear in the command
      final allVars = RemoteProviderRegistry.allEnvVarNames;
      expect(allVars.length, 12); // 11 providers, 1 with dual vars (Google)

      for (final varName in allVars) {
        expect(
          capturedCommand,
          contains(varName),
          reason: 'Command should check for $varName',
        );
      }
    });

    // @telos-scenario L1:...:env_provider_detector:multi-chunk-stdout
    test('handles stdout delivered in multiple chunks', () async {
      final session = MockSSHSession();
      final chunk1 = Uint8List.fromList(utf8.encode('ANTHROPIC_API_KEY\n'));
      final chunk2 = Uint8List.fromList(utf8.encode('OPENAI_API_KEY\n'));
      final chunk3 = Uint8List.fromList(utf8.encode('$_sentinel\n'));

      when(() => session.stdout).thenAnswer(
        (_) => Stream.fromIterable([chunk1, chunk2, chunk3]),
      );

      when(() => mockClient.execute(any())).thenAnswer((_) async => session);

      final result = await detector.detect(mockClient);

      expect(result.providers, hasLength(2));
      expect(result.providers[0].provider, RemoteCloudProvider.anthropic);
      expect(result.providers[1].provider, RemoteCloudProvider.openai);
      expect(result.method, RemoteDetectionMethod.direct);
    });
  });
}
