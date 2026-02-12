// @telos-test L1:function:lib/features/ai/domain/entities:remote_ai_provider

import 'package:bento/features/ai/domain/entities/remote_ai_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteProviderRegistry', () {
    // @telos-scenario L1:...:remote_ai_provider:all-providers-present
    test('contains all 11 providers', () {
      expect(RemoteProviderRegistry.providers.length, 11);
    });

    // @telos-scenario L1:...:remote_ai_provider:env-vars-unique
    test('all env var names are unique across providers', () {
      final allVars = RemoteProviderRegistry.allEnvVarNames;
      expect(allVars.toSet().length, allVars.length);
    });

    // @telos-scenario L1:...:remote_ai_provider:env-var-count
    test('has exactly 12 env var names', () {
      // 11 providers, 1 with dual vars (Google: GOOGLE_API_KEY + GEMINI_API_KEY)
      // NOTE: CLAUDE_CODE_OAUTH_TOKEN was removed from Anthropic because it
      // uses Authorization: Bearer format, incompatible with x-api-key auth.
      final allVars = RemoteProviderRegistry.allEnvVarNames;
      expect(allVars.length, 12);
    });

    // @telos-scenario L1:...:remote_ai_provider:lookup-by-env-var
    test('forEnvVar returns correct provider config', () {
      final config = RemoteProviderRegistry.forEnvVar('ANTHROPIC_API_KEY');
      expect(config, isNotNull);
      expect(config!.provider, RemoteCloudProvider.anthropic);
      expect(config.apiFormat, ApiFormat.anthropicMessages);
    });

    // @telos-scenario L1:...:remote_ai_provider:lookup-by-env-var-secondary
    test('forEnvVar works for secondary env vars', () {
      final config = RemoteProviderRegistry.forEnvVar('GEMINI_API_KEY');
      expect(config, isNotNull);
      expect(config!.provider, RemoteCloudProvider.google);
    });

    // @telos-scenario L1:...:remote_ai_provider:lookup-by-env-var-unknown
    test('forEnvVar returns null for unknown env var', () {
      final config = RemoteProviderRegistry.forEnvVar('UNKNOWN_KEY');
      expect(config, isNull);
    });

    // @telos-scenario L1:...:remote_ai_provider:lookup-by-provider
    test('forProvider returns correct config', () {
      final config =
          RemoteProviderRegistry.forProvider(RemoteCloudProvider.openai);
      expect(config, isNotNull);
      expect(config!.displayName, 'GPT-4o (OpenAI)');
      expect(config.apiFormat, ApiFormat.openaiCompatible);
    });

    // @telos-scenario L1:...:remote_ai_provider:quality-rank-ordering
    test('providers are ordered by quality rank', () {
      final ranks =
          RemoteProviderRegistry.providers.map((p) => p.qualityRank).toList();
      final sorted = List<int>.from(ranks)..sort();
      expect(ranks, sorted);
    });

    // @telos-scenario L1:...:remote_ai_provider:anthropic-is-rank-1
    test('Anthropic has rank 1 (best)', () {
      final config =
          RemoteProviderRegistry.forProvider(RemoteCloudProvider.anthropic);
      expect(config!.qualityRank, 1);
    });

    // @telos-scenario L1:...:remote_ai_provider:anthropic-uses-messages-api
    test('Anthropic uses Messages API format', () {
      final config =
          RemoteProviderRegistry.forProvider(RemoteCloudProvider.anthropic);
      expect(config!.apiFormat, ApiFormat.anthropicMessages);
      expect(config.authHeaderName, 'x-api-key');
    });

    // @telos-scenario L1:...:remote_ai_provider:openai-uses-bearer-auth
    test('OpenAI uses Bearer auth', () {
      final config =
          RemoteProviderRegistry.forProvider(RemoteCloudProvider.openai);
      expect(config!.authHeaderName, 'Authorization');
      expect(config.authHeaderFormat, contains('Bearer'));
    });
  });
}
