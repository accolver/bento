// @telos L1:function:lib/features/ai/data/services:unconfigured_ai_service

import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';

/// AI service placeholder when AI is not configured.
///
/// Returns errors prompting the user to configure AI.
/// This replaces the old MockAiService which used keyword matching.
class UnconfiguredAiService implements AiService {
  const UnconfiguredAiService();

  @override
  String get serviceName => 'Not Configured';

  @override
  AiPrivacyMode get privacyMode => AiPrivacyMode.local;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> dispose() async {
    // No resources to clean up
  }

  @override
  Future<AiSuggestion> generateCommand(String input) async {
    throw const AiNotConfiguredException();
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(String prompt) async* {
    yield const AiStreamError('AI is not configured. Please set up AI first.');
  }

  @override
  Future<String> summarizeOutput(String command, String output) async {
    throw const AiNotConfiguredException();
  }
}

/// Exception thrown when AI service is used but not configured.
class AiNotConfiguredException implements Exception {
  const AiNotConfiguredException();

  @override
  String toString() => 'AI is not configured. Please set up AI first.';
}
