# Claude Code Remote AI Detection — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to
> implement this plan task-by-task.

**Goal:** Detect Claude Code on remote SSH hosts and use its OAuth credentials
to make Anthropic API calls, key-opaque (tokens never leave the remote machine).

**Architecture:** New `ClaudeCodeDetector` alongside existing
`OllamaDetector`/`EnvProviderDetector`. Claude Code becomes a new
`RemoteCloudProvider` enum value with rank 0 (highest priority). The
`CloudProxyBackend` gains a Bearer auth code path using shell-expanded token
extraction from `~/.claude/.credentials`.

**Tech Stack:** Flutter/Dart, dartssh2 (SSH), Riverpod, mocktail (testing)

**Design doc:** `docs/plans/2026-02-28-claude-code-remote-detection-design.md`

---

## Task 1: Add `claudeCode` to Provider Enum and Registry

**Files:**

- Modify: `lib/features/ai/domain/entities/remote_ai_provider.dart`

**Step 1: Add enum value**

In `remote_ai_provider.dart`, add `claudeCode` as the first enum value (before
`anthropic`) in `RemoteCloudProvider`:

```dart
enum RemoteCloudProvider {
  /// Claude Code — OAuth-based Anthropic access via installed CLI
  claudeCode,

  /// Anthropic — Claude models, best reasoning for terminal commands
  anthropic,
  // ... rest unchanged
}
```

**Step 2: Add provider config to registry**

In the `RemoteProviderRegistry.providers` const list, add Claude Code as the
first entry (rank 0):

```dart
static const providers = <RemoteProviderConfig>[
  // Claude Code — detected via ~/.claude/.credentials file, not env vars
  RemoteProviderConfig(
    provider: RemoteCloudProvider.claudeCode,
    envVars: [], // file-based detection, not env var
    displayName: 'Claude Code',
    apiBaseUrl: 'https://api.anthropic.com',
    defaultModel: 'claude-sonnet-4-5-20250514',
    apiFormat: ApiFormat.anthropicMessages,
    authHeaderName: 'Authorization',
    authHeaderFormat: r'Bearer $KEY',
    qualityRank: 0,
  ),
  // Anthropic — rank 1
  // ... rest unchanged
];
```

**Step 3: Run analyzer**

Run: `flutter analyze lib/features/ai/domain/entities/remote_ai_provider.dart`
Expected: No errors (the enum value is additive)

**Step 4: Commit**

```
feat(ai): add claudeCode to RemoteCloudProvider enum and registry
```

---

## Task 2: Add Claude Code Fields to Detection Result

**Files:**

- Modify: `lib/features/ai/domain/entities/remote_ai_detection.dart`
- Test: `test/features/ai/domain/entities/remote_ai_detection_test.dart` (create
  if not exists)

**Step 1: Write failing test**

Create `test/features/ai/domain/entities/remote_ai_detection_test.dart`:

```dart
// @telos-test L1:function:lib/features/ai/domain/entities:remote_ai_detection

import 'package:bento/features/ai/domain/entities/remote_ai_detection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteAiDetectionResult', () {
    // @telos-scenario L1:...:remote_ai_detection:claude-code-detected
    test('hasAnyProvider is true when claudeCodeDetected is true', () {
      final result = RemoteAiDetectionResult(
        hostId: 'test-host',
        claudeCodeDetected: true,
        claudeCodeVersion: '2.1.0',
        checkedAt: DateTime.now(),
      );

      expect(result.hasAnyProvider, isTrue);
      expect(result.claudeCodeDetected, isTrue);
      expect(result.claudeCodeVersion, '2.1.0');
    });

    // @telos-scenario L1:...:remote_ai_detection:claude-code-not-detected
    test('claudeCode fields default to false/null', () {
      final result = RemoteAiDetectionResult(
        hostId: 'test-host',
        checkedAt: DateTime.now(),
      );

      expect(result.claudeCodeDetected, isFalse);
      expect(result.claudeCodeVersion, isNull);
    });

    // @telos-scenario L1:...:remote_ai_detection:provider-count-with-claude-code
    test('providerCount includes Claude Code', () {
      final result = RemoteAiDetectionResult(
        hostId: 'test-host',
        claudeCodeDetected: true,
        checkedAt: DateTime.now(),
      );

      expect(result.providerCount, 1);
    });

    // @telos-scenario L1:...:remote_ai_detection:empty-has-no-claude-code
    test('empty result has no Claude Code', () {
      final result = RemoteAiDetectionResult.empty('test-host');

      expect(result.claudeCodeDetected, isFalse);
      expect(result.claudeCodeVersion, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run:
`flutter test test/features/ai/domain/entities/remote_ai_detection_test.dart`
Expected: FAIL — `claudeCodeDetected` parameter doesn't exist yet

**Step 3: Add fields to `RemoteAiDetectionResult`**

In `remote_ai_detection.dart`, modify the class (around line 53):

```dart
class RemoteAiDetectionResult {
  const RemoteAiDetectionResult({
    required this.hostId,
    this.ollamaModels = const [],
    this.cloudProviders = const [],
    this.claudeCodeDetected = false,
    this.claudeCodeVersion,
    required this.checkedAt,
    this.detectionMethod = RemoteDetectionMethod.direct,
  });

  final String hostId;
  final List<OllamaModel> ollamaModels;
  final List<DetectedCloudProvider> cloudProviders;

  /// Whether Claude Code was detected on the remote host.
  final bool claudeCodeDetected;

  /// Claude Code version string (e.g., "2.1.0"), null if not detected.
  final String? claudeCodeVersion;

  final DateTime checkedAt;
  final RemoteDetectionMethod detectionMethod;

  bool get hasAnyProvider =>
      ollamaModels.isNotEmpty ||
      cloudProviders.isNotEmpty ||
      claudeCodeDetected;

  bool get hasOllama => ollamaModels.isNotEmpty;
  bool get hasCloudProviders => cloudProviders.isNotEmpty;

  int get providerCount =>
      (hasOllama ? 1 : 0) +
      cloudProviders.length +
      (claudeCodeDetected ? 1 : 0);

  // bestCloudProvider, isStale, empty(), toString() — update accordingly
}
```

Update `toString()` to include Claude Code info.

Update `factory RemoteAiDetectionResult.empty()` — `claudeCodeDetected` defaults
to `false` already so no change needed.

**Step 4: Run test to verify it passes**

Run:
`flutter test test/features/ai/domain/entities/remote_ai_detection_test.dart`
Expected: PASS

**Step 5: Run existing tests to check for regressions**

Run: `flutter test test/features/ai/` Expected: All pass (new fields have
defaults, so existing callers unaffected)

**Step 6: Commit**

```
feat(ai): add claudeCodeDetected and claudeCodeVersion to RemoteAiDetectionResult
```

---

## Task 3: Create `ClaudeCodeDetector`

**Files:**

- Create: `lib/features/ai/data/services/claude_code_detector.dart`
- Create: `test/features/ai/data/services/claude_code_detector_test.dart`

**Step 1: Write failing tests**

Create `test/features/ai/data/services/claude_code_detector_test.dart`:

```dart
// @telos-test L1:function:lib/features/ai/data/services:claude_code_detector

import 'dart:convert';
import 'dart:typed_data';

import 'package:bento/features/ai/data/services/claude_code_detector.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSSHClient extends Mock implements SSHClient {}

class MockSSHSession extends Mock implements SSHSession {}

void main() {
  late MockSSHClient client;
  late ClaudeCodeDetector detector;

  SSHSession _sessionWithOutput(String stdout, {int exitCode = 0}) {
    final session = MockSSHSession();
    when(() => session.stdout).thenAnswer(
      (_) => Stream.value(Uint8List.fromList(utf8.encode(stdout))),
    );
    when(() => session.stderr).thenAnswer(
      (_) => Stream.value(Uint8List.fromList(utf8.encode(''))),
    );
    when(() => session.exitCode).thenAnswer((_) async => exitCode);
    return session;
  }

  setUp(() {
    client = MockSSHClient();
    detector = const ClaudeCodeDetector();
  });

  group('ClaudeCodeDetector', () {
    // @telos-scenario L1:...:claude_code_detector:detect-found
    test('detects Claude Code when credentials file exists', () async {
      // Detection command succeeds
      when(() => client.execute(any())).thenAnswer(
        (_) async => _sessionWithOutput('CLAUDE_CODE_FOUND\n'),
      );

      final result = await detector.detect(client);

      expect(result.detected, isTrue);
    });

    // @telos-scenario L1:...:claude_code_detector:detect-not-found
    test('returns not detected when credentials file missing', () async {
      when(() => client.execute(any())).thenAnswer(
        (_) async => _sessionWithOutput('', exitCode: 1),
      );

      final result = await detector.detect(client);

      expect(result.detected, isFalse);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:detect-with-version
    test('captures version when Claude CLI available', () async {
      // First call: detection
      // Second call: version
      var callCount = 0;
      when(() => client.execute(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return _sessionWithOutput('CLAUDE_CODE_FOUND\n');
        }
        return _sessionWithOutput('2.1.62\n');
      });

      final result = await detector.detect(client);

      expect(result.detected, isTrue);
      expect(result.version, '2.1.62');
    });

    // @telos-scenario L1:...:claude_code_detector:detect-version-unavailable
    test('returns null version when claude CLI not found', () async {
      var callCount = 0;
      when(() => client.execute(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return _sessionWithOutput('CLAUDE_CODE_FOUND\n');
        }
        return _sessionWithOutput('unknown\n', exitCode: 127);
      });

      final result = await detector.detect(client);

      expect(result.detected, isTrue);
      expect(result.version, isNull);
    });

    // @telos-scenario L1:...:claude_code_detector:detect-timeout
    test('returns not detected on timeout', () async {
      when(() => client.execute(any())).thenThrow(
        TimeoutException('SSH timeout'),
      );

      final result = await detector.detect(client);

      expect(result.detected, isFalse);
    });

    // @telos-scenario L1:...:claude_code_detector:detect-ssh-exception
    test('returns not detected on SSH exception', () async {
      when(() => client.execute(any())).thenThrow(
        Exception('SSH connection lost'),
      );

      final result = await detector.detect(client);

      expect(result.detected, isFalse);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run:
`flutter test test/features/ai/data/services/claude_code_detector_test.dart`
Expected: FAIL — `ClaudeCodeDetector` class doesn't exist

**Step 3: Implement `ClaudeCodeDetector`**

Create `lib/features/ai/data/services/claude_code_detector.dart`:

```dart
// @telos L1:function:lib/features/ai/data/services:claude_code_detector

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../utils/ssh_utils.dart';

/// Result of Claude Code detection on a remote host.
class ClaudeCodeDetectionResult {
  const ClaudeCodeDetectionResult({
    required this.detected,
    this.version,
  });

  /// Whether Claude Code was found on the remote host.
  final bool detected;

  /// Claude Code version string, or null if not available.
  final String? version;

  /// Not detected result.
  static const notDetected = ClaudeCodeDetectionResult(detected: false);
}

/// Detects whether Claude Code is installed on a remote SSH host.
///
/// Checks for the presence of `~/.claude/.credentials`, which indicates
/// Claude Code is installed and has been authenticated. This is distinct
/// from checking for `ANTHROPIC_API_KEY` env var — a user may have a
/// Claude Max subscription via Claude Code but no raw API key.
///
/// Like [EnvProviderDetector], this never reads credential values.
/// Detection only checks file existence via `test -f`.
class ClaudeCodeDetector {
  const ClaudeCodeDetector();

  /// Detection sentinel echoed when Claude Code is found.
  static const _sentinel = 'CLAUDE_CODE_FOUND';

  /// Detect Claude Code on the remote host.
  ///
  /// Returns a [ClaudeCodeDetectionResult] indicating whether Claude Code
  /// was found and optionally its version.
  Future<ClaudeCodeDetectionResult> detect(SSHClient client) async {
    try {
      // Check for credentials file existence
      final detectionCmd =
          'test -d ~/.claude && test -f ~/.claude/.credentials '
          '&& echo "$_sentinel"';

      final session = await client
          .execute(detectionCmd)
          .timeout(const Duration(seconds: 10));

      final stdout = await SshUtils.collectOutput(session.stdout);
      final exitCode = await session.exitCode;

      if (exitCode != 0 || !stdout.contains(_sentinel)) {
        debugPrint('[ClaudeCodeDetector] Not found (exit=$exitCode)');
        return ClaudeCodeDetectionResult.notDetected;
      }

      debugPrint('[ClaudeCodeDetector] Found Claude Code');

      // Try to get version
      final version = await _getVersion(client);

      return ClaudeCodeDetectionResult(
        detected: true,
        version: version,
      );
    } on TimeoutException {
      debugPrint('[ClaudeCodeDetector] Detection timed out');
      return ClaudeCodeDetectionResult.notDetected;
    } catch (e) {
      debugPrint('[ClaudeCodeDetector] Detection error: $e');
      return ClaudeCodeDetectionResult.notDetected;
    }
  }

  /// Try to get the Claude Code version from the remote host.
  ///
  /// Returns null if the `claude` CLI is not in PATH or fails.
  Future<String?> _getVersion(SSHClient client) async {
    try {
      final session = await client
          .execute('claude --version 2>/dev/null')
          .timeout(const Duration(seconds: 5));

      final stdout = await SshUtils.collectOutput(session.stdout);
      final exitCode = await session.exitCode;

      if (exitCode != 0) return null;

      final version = stdout.trim();
      if (version.isEmpty || version == 'unknown') return null;

      return version;
    } catch (_) {
      return null;
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run:
`flutter test test/features/ai/data/services/claude_code_detector_test.dart`
Expected: PASS

**Step 5: Commit**

```
feat(ai): add ClaudeCodeDetector for remote Claude Code detection
```

---

## Task 4: Integrate ClaudeCodeDetector into RemoteAiDetector

**Files:**

- Modify: `lib/features/ai/data/services/remote_ai_detector.dart`
- Modify: `test/features/ai/data/services/remote_ai_detector_test.dart`

**Step 1: Write failing tests**

Add to `test/features/ai/data/services/remote_ai_detector_test.dart`:

Add `MockClaudeCodeDetector` mock class and update setUp to inject it.

Add new test group:

```dart
class MockClaudeCodeDetector extends Mock implements ClaudeCodeDetector {}

// In setUp:
late MockClaudeCodeDetector mockClaudeCodeDetector;
// mockClaudeCodeDetector = MockClaudeCodeDetector();
// Pass to RemoteAiDetector constructor

group('claude code detection', () {
  test('includes Claude Code in result when detected', () async {
    // Stub Ollama and env as empty
    when(() => mockOllamaDetector.detect(any()))
        .thenAnswer((_) async => []);
    when(() => mockEnvDetector.detect(any()))
        .thenAnswer((_) async => (
              providers: <DetectedCloudProvider>[],
              method: RemoteDetectionMethod.direct,
            ));
    when(() => mockClaudeCodeDetector.detect(any()))
        .thenAnswer((_) async => const ClaudeCodeDetectionResult(
              detected: true,
              version: '2.1.62',
            ));

    final result = await detector.detect(
      hostId: 'test-host',
      client: mockClient,
    );

    expect(result.claudeCodeDetected, isTrue);
    expect(result.claudeCodeVersion, '2.1.62');
    expect(result.hasAnyProvider, isTrue);
  });

  test('emits detected event when only Claude Code found', () async {
    when(() => mockOllamaDetector.detect(any()))
        .thenAnswer((_) async => []);
    when(() => mockEnvDetector.detect(any()))
        .thenAnswer((_) async => (
              providers: <DetectedCloudProvider>[],
              method: RemoteDetectionMethod.direct,
            ));
    when(() => mockClaudeCodeDetector.detect(any()))
        .thenAnswer((_) async => const ClaudeCodeDetectionResult(
              detected: true,
            ));

    final eventFuture = detector.detectionEvents.first;
    await detector.detect(hostId: 'test-host', client: mockClient);
    final event = await eventFuture;

    expect(event, isA<RemoteAiDetectedEvent>());
  });
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/ai/data/services/remote_ai_detector_test.dart`
Expected: FAIL — constructor doesn't accept `claudeCodeDetector`

**Step 3: Update RemoteAiDetector**

In `remote_ai_detector.dart`:

```dart
import 'claude_code_detector.dart';

class RemoteAiDetector {
  RemoteAiDetector({
    OllamaDetector? ollamaDetector,
    EnvProviderDetector? envProviderDetector,
    ClaudeCodeDetector? claudeCodeDetector,
  })  : _ollamaDetector = ollamaDetector ?? const OllamaDetector(),
        _envProviderDetector =
            envProviderDetector ?? const EnvProviderDetector(),
        _claudeCodeDetector =
            claudeCodeDetector ?? const ClaudeCodeDetector();

  final OllamaDetector _ollamaDetector;
  final EnvProviderDetector _envProviderDetector;
  final ClaudeCodeDetector _claudeCodeDetector;

  // ... cache and stream unchanged ...

  Future<RemoteAiDetectionResult> detect({
    required String hostId,
    required SSHClient client,
  }) async {
    debugPrint('[RemoteAiDetector] Starting detection for $hostId');

    // Run all three detections in parallel
    final ollamaFuture = _ollamaDetector.detect(client);
    final envFuture = _envProviderDetector.detect(client);
    final claudeCodeFuture = _claudeCodeDetector.detect(client);

    final ollamaModels = await ollamaFuture;
    final envResult = await envFuture;
    final claudeCodeResult = await claudeCodeFuture;

    final detectionResult = RemoteAiDetectionResult(
      hostId: hostId,
      ollamaModels: ollamaModels ?? [],
      cloudProviders: envResult.providers,
      claudeCodeDetected: claudeCodeResult.detected,
      claudeCodeVersion: claudeCodeResult.version,
      checkedAt: DateTime.now(),
      detectionMethod: envResult.method,
    );

    _cache[hostId] = detectionResult;

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
        reason: 'No Ollama, cloud provider env vars, or Claude Code detected',
      ));
    }

    return detectionResult;
  }

  // ... rest unchanged ...
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/ai/data/services/remote_ai_detector_test.dart`
Expected: All pass (existing + new)

**Step 5: Commit**

```
feat(ai): integrate ClaudeCodeDetector into RemoteAiDetector orchestrator
```

---

## Task 5: Add Bearer Auth to CloudProxyBackend

**Files:**

- Modify: `lib/features/ai/data/services/cloud_proxy_backend.dart`
- Modify existing tests or create new ones for the Bearer auth path

**Step 1: Write failing test**

Add test verifying that when `providerConfig.provider` is
`RemoteCloudProvider.claudeCode`, the curl command uses `Authorization: Bearer`
with a shell-expanded token extraction instead of `x-api-key: $ENV_VAR`.

The `_buildAnthropicCurl` method currently hardcodes `x-api-key`. For Claude
Code, it needs to use `Authorization: Bearer $(...)` with the token extraction
command.

Key insight: `CloudProxyBackend` is constructed with an `envVarName`. For Claude
Code, `envVarName` is meaningless (there's no env var). Instead, we need a new
subclass or a conditional path.

**Approach**: Create `ClaudeCodeProxyBackend extends CloudProxyBackend` that
overrides `_buildAnthropicCurl` to use the credentials file extraction. This
keeps `CloudProxyBackend` clean and follows OCP.

Create test:

```dart
// In test/features/ai/data/services/claude_code_proxy_backend_test.dart

// @telos-test L1:function:lib/features/ai/data/services:claude_code_proxy_backend

import 'package:bento/features/ai/data/services/claude_code_proxy_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClaudeCodeProxyBackend', () {
    test('curl command uses Bearer auth with credentials file extraction', () {
      final backend = ClaudeCodeProxyBackend();

      // Access the internal curl builder (or test via a public method)
      expect(backend.displayName, 'Claude Code');
      expect(backend.isConfigured, isTrue);
    });
  });
}
```

**Step 2: Implement `ClaudeCodeProxyBackend`**

Create `lib/features/ai/data/services/claude_code_proxy_backend.dart`:

```dart
// @telos L1:function:lib/features/ai/data/services:claude_code_proxy_backend

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/ai_suggestion.dart';
import '../../domain/entities/remote_ai_provider.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/prompt_templates.dart';
import '../utils/response_parser.dart';
import '../utils/shell_escape.dart';
import '../utils/ssh_utils.dart';
import 'remote_ai_exceptions.dart';
import 'remote_backend.dart';

/// Shell command to extract Claude Code OAuth token from credentials file.
///
/// Uses python3 for JSON parsing with grep/cut fallback.
/// Runs entirely on the remote host — token never reaches Bento.
const _tokenExtraction = r'''$(python3 -c "import json; print(json.load(open('$HOME/.claude/.credentials')).get('claudeApiKey', json.load(open('$HOME/.claude/.credentials')).get('oauthToken', '')))" 2>/dev/null || grep -o '"claudeApiKey":"[^"]*"\|"oauthToken":"[^"]*"' ~/.claude/.credentials | head -1 | cut -d'"' -f4)''';

/// Remote backend for proxying API calls through Claude Code's OAuth
/// credentials on a remote SSH host.
///
/// Unlike [CloudProxyBackend] which uses env var shell expansion,
/// this backend extracts the OAuth token from `~/.claude/.credentials`
/// using shell commands. The token value never reaches Bento.
///
/// ## Auth Differences from CloudProxyBackend
///
/// - Uses `Authorization: Bearer <token>` instead of `x-api-key: <env_var>`
/// - Token is extracted from a JSON file, not an environment variable
/// - Supports automatic token refresh via `claude --print-access-token`
class ClaudeCodeProxyBackend extends RemoteBackend {
  ClaudeCodeProxyBackend({
    this.maxTokens = 256,
    this.temperature = 0.3,
  });

  final int maxTokens;
  final double temperature;

  /// The default model to use.
  String get _model =>
      RemoteProviderRegistry.forProvider(RemoteCloudProvider.claudeCode)
          .defaultModel;

  @override
  bool get isConfigured => true; // Configured if detector found it

  @override
  String get displayName => 'Claude Code';

  @override
  String get privacyDescription =>
      'API calls via Claude Code OAuth on remote host. '
      'Tokens never leave the remote machine.';

  @override
  Future<AiSuggestion> generateCommand(
    SSHClient client,
    String prompt,
  ) async {
    final curl = _buildCurlCommand(
      systemPrompt: PromptTemplates.commandGeneration.system,
      userPrompt: PromptTemplates.commandGeneration.user(prompt),
      stream: false,
    );

    final session =
        await client.execute(curl).timeout(const Duration(seconds: 30));
    final stdout = await SshUtils.collectOutput(session.stdout);
    final exitCode = await session.exitCode;

    if (exitCode == 127) {
      throw CurlNotFoundException();
    }

    if (exitCode != 0) {
      // Check for auth failure — may need token refresh
      if (_isAuthError(stdout)) {
        await _attemptTokenRefresh(client);
        // Retry once after refresh
        return generateCommand(client, prompt);
      }
      throw RemoteApiException(
        'Claude Code API error (exit $exitCode)',
        statusCode: exitCode,
        body: stdout,
      );
    }

    _checkForApiErrors(stdout);
    return ResponseParser.parseAnthropicCommand(stdout);
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(
    SSHClient client,
    String prompt,
  ) async* {
    // Similar to CloudProxyBackend streaming but with Bearer auth
    // Implementation follows the same pattern
    final curl = _buildCurlCommand(
      systemPrompt: PromptTemplates.commandGeneration.system,
      userPrompt: PromptTemplates.commandGeneration.user(prompt),
      stream: true,
    );

    try {
      final session =
          await client.execute(curl).timeout(const Duration(seconds: 30));

      await for (final chunk in session.stdout) {
        final text = utf8.decode(chunk, allowMalformed: true);
        final lines = text.split('\n');

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') continue;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta = (json['delta'] as Map<String, dynamic>?);
            if (delta != null && delta['type'] == 'text_delta') {
              yield AiStreamToken(delta['text'] as String);
            }
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }

      yield AiStreamComplete(
        AiSuggestion(
          command: 'completed',
          explanation: 'Stream complete',
          confidence: 0.85,
        ),
      );
    } catch (e) {
      yield AiStreamError(
        'Claude Code streaming error: $e',
        code: 'stream_error',
        originalError: e,
      );
    }
  }

  @override
  Future<String> summarizeOutput(
    SSHClient client,
    String command,
    String output,
  ) async {
    final truncated =
        output.length > 1500 ? '${output.substring(0, 1500)}...' : output;

    final curl = _buildCurlCommand(
      systemPrompt: PromptTemplates.summarization.system,
      userPrompt: PromptTemplates.summarization.user(
        command: command,
        output: truncated,
      ),
      stream: false,
    );

    final session =
        await client.execute(curl).timeout(const Duration(seconds: 30));
    final stdout = await SshUtils.collectOutput(session.stdout);
    final exitCode = await session.exitCode;

    if (exitCode != 0) return 'Unable to generate summary.';

    try {
      _checkForApiErrors(stdout);
      return ResponseParser.extractAnthropicContent(stdout);
    } catch (e) {
      debugPrint('[ClaudeCodeProxyBackend] Summary parse error: $e');
      return 'Unable to generate summary.';
    }
  }

  /// Build curl command with Claude Code OAuth Bearer auth.
  ///
  /// The token is extracted from ~/.claude/.credentials via shell expansion.
  /// It never appears in Bento's memory.
  String _buildCurlCommand({
    required String systemPrompt,
    required String userPrompt,
    required bool stream,
  }) {
    final body = {
      'model': _model,
      'system': systemPrompt,
      'messages': [
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': maxTokens,
      if (stream) 'stream': true,
    };

    final escapedBody = ShellEscape.escape(jsonEncode(body));

    return 'curl -s${stream ? 'N' : ''} '
        'https://api.anthropic.com/v1/messages '
        '-H "Authorization: Bearer $_tokenExtraction" '
        "-H 'anthropic-version: 2023-06-01' "
        "-H 'Content-Type: application/json' "
        "-d '$escapedBody'";
  }

  /// Check if API response indicates an authentication error.
  bool _isAuthError(String response) {
    try {
      final json = jsonDecode(response) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['type'] == 'authentication_error';
    } catch (_) {
      return response.contains('authentication_error') ||
          response.contains('401');
    }
  }

  /// Attempt to refresh the Claude Code OAuth token on the remote host.
  ///
  /// Runs `claude --print-access-token` which triggers Claude Code's
  /// internal refresh mechanism. The new token is written to
  /// `~/.claude/.credentials` and subsequent requests pick it up.
  Future<void> _attemptTokenRefresh(SSHClient client) async {
    try {
      debugPrint('[ClaudeCodeProxyBackend] Attempting token refresh...');

      final session = await client
          .execute('claude --print-access-token 2>/dev/null')
          .timeout(const Duration(seconds: 15));

      final exitCode = await session.exitCode;

      if (exitCode != 0) {
        throw RemoteApiException(
          'Claude Code session expired. SSH into the remote host and run '
          "'claude' to re-authenticate.",
          statusCode: 401,
        );
      }

      debugPrint('[ClaudeCodeProxyBackend] Token refreshed successfully');
    } catch (e) {
      if (e is RemoteApiException) rethrow;
      throw RemoteApiException(
        'Unable to refresh Claude Code token. SSH into the remote host '
        "and run 'claude' to re-authenticate.",
        statusCode: 401,
      );
    }
  }

  /// Check response body for API error responses.
  void _checkForApiErrors(String response) {
    try {
      final json = jsonDecode(response) as Map<String, dynamic>;
      if (json.containsKey('error')) {
        final error = json['error'] as Map<String, dynamic>;
        final type = error['type'] as String? ?? 'unknown';
        final message = error['message'] as String? ?? 'Unknown error';

        if (type == 'rate_limit_error') {
          throw RateLimitException(message);
        }
        if (type == 'authentication_error') {
          throw RemoteApiException(
            'Claude Code authentication failed: $message',
            statusCode: 401,
          );
        }
        throw RemoteApiException(message, statusCode: 400, body: response);
      }
    } catch (e) {
      if (e is RateLimitException || e is RemoteApiException) rethrow;
      // Not JSON or no error field — response is probably valid
    }
  }
}
```

**Step 3: Run tests**

Run:
`flutter test test/features/ai/data/services/claude_code_proxy_backend_test.dart`
Expected: PASS

**Step 4: Commit**

```
feat(ai): add ClaudeCodeProxyBackend with Bearer auth and token refresh
```

---

## Task 6: Update UI — RemoteProviderSelector

**Files:**

- Modify: `lib/features/ai/presentation/widgets/remote_provider_selector.dart`

**Step 1: Add Claude Code tile section**

In `RemoteProviderSelector.build()`, add a section for Claude Code above the
cloud providers section when `detectionResult.claudeCodeDetected` is true:

```dart
// Before the cloud providers section, add:
if (detectionResult.claudeCodeDetected) ...[
  const _SectionHeader(title: 'Claude Code'),
  _ClaudeCodeTile(
    version: detectionResult.claudeCodeVersion,
    isActive: _isClaudeCodeActive(),
    onTap: () => _selectClaudeCode(),
  ),
  const SizedBox(height: 16),
],
```

Add `_isClaudeCodeActive()` method:

```dart
bool _isClaudeCodeActive(WidgetRef ref) {
  final config = ref.read(remoteAiConfigStateProvider(hostId));
  return config.value?.backend is ClaudeCodeProxyBackend;
}
```

Add `_selectClaudeCode()` method:

```dart
void _selectClaudeCode(WidgetRef ref) {
  final backend = ClaudeCodeProxyBackend();
  ref.read(remoteAiServiceControllerProvider(hostId).notifier)
      .switchBackend(backend);
  Navigator.pop(context);
}
```

Add `_ClaudeCodeTile` widget:

```dart
class _ClaudeCodeTile extends StatelessWidget {
  const _ClaudeCodeTile({
    required this.version,
    required this.isActive,
    required this.onTap,
  });

  final String? version;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.auto_awesome, color: Colors.deepOrange),
      title: const Text('Claude Code'),
      subtitle: Text(version != null ? 'v$version' : 'OAuth session'),
      trailing: isActive
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
```

**Step 2: Run analyzer**

Run:
`flutter analyze lib/features/ai/presentation/widgets/remote_provider_selector.dart`
Expected: No errors

**Step 3: Commit**

```
feat(ai): add Claude Code option to RemoteProviderSelector UI
```

---

## Task 7: Update UI — RemoteAiStatus

**Files:**

- Modify: `lib/features/ai/presentation/widgets/remote_ai_status.dart`

**Step 1: Add Claude Code status indicator**

In the build method's state logic (around line 44-60), add a case for
`ClaudeCodeProxyBackend`:

```dart
// Add import for ClaudeCodeProxyBackend
// In the icon/label determination logic:
if (backend is ClaudeCodeProxyBackend) {
  icon = Icons.auto_awesome;
  label = 'Claude Code';
  color = Colors.deepOrange;
}
```

**Step 2: Run analyzer**

Run:
`flutter analyze lib/features/ai/presentation/widgets/remote_ai_status.dart`
Expected: No errors

**Step 3: Commit**

```
feat(ai): show Claude Code status in RemoteAiStatus widget
```

---

## Task 8: Update Providers — Wire Up Auto-Selection

**Files:**

- Modify: `lib/features/ai/presentation/providers/remote_ai_providers.dart`

**Step 1: Update `_createBackend()` in `RemoteAiServiceController`**

In the auto-select logic (around lines 288-338), add Claude Code as the highest
priority auto-selection:

```dart
// In _createBackend(), add at the start of the auto-select logic:
if (detectionResult?.claudeCodeDetected == true) {
  debugPrint('[RemoteAiServiceController] Auto-selecting Claude Code');
  return ClaudeCodeProxyBackend();
}
```

This runs before the existing Ollama and cloud provider auto-selection, making
Claude Code the preferred backend when detected.

**Step 2: Run analyzer**

Run:
`flutter analyze lib/features/ai/presentation/providers/remote_ai_providers.dart`
Expected: No errors

**Step 3: Commit**

```
feat(ai): auto-select Claude Code as preferred remote AI backend
```

---

## Task 9: Run Full Test Suite and Fix Regressions

**Step 1: Run all AI tests**

Run: `flutter test test/features/ai/`

**Step 2: Fix any failures**

Most likely issues:

- Existing `RemoteAiDetector` tests may need updating to stub the new
  `ClaudeCodeDetector` dependency
- Provider tests may need to account for the new `claudeCode` enum value

**Step 3: Run full test suite**

Run: `flutter test`

**Step 4: Run analyzer**

Run: `flutter analyze`

**Step 5: Commit any fixes**

```
fix(ai): update tests for Claude Code integration
```

---

## Task 10: Build Verification

**Step 1: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

(Riverpod codegen may need regeneration if providers changed)

**Step 2: Run build**

Run: `flutter build apk --debug`

**Step 3: Run analyzer one final time**

Run: `flutter analyze`

**Step 4: Final commit**

```
chore: regenerate codegen and verify build for Claude Code feature
```
