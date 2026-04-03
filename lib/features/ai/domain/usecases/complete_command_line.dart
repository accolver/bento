// @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine

import 'package:fpdart/fpdart.dart';

import '../../data/services/unconfigured_ai_service.dart';
import '../entities/ai_config.dart';
import '../entities/ai_failure.dart';
import '../entities/ai_privacy_mode.dart';
import '../entities/ai_suggestion.dart';
import '../entities/command_suggestion.dart';
import '../entities/shell_context.dart';
import '../services/ai_service.dart';

/// Explicit AI refinement of the current shell line.
class CompleteCommandLine {
  // @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine
  const CompleteCommandLine({
    required AiService service,
    required AiConfig config,
  })  : _service = service,
        _config = config;

  final AiService _service;
  final AiConfig _config;

  // @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine
  Future<Either<AIFailure, CommandSuggestion>> call({
    required String partialLine,
    required ShellContext context,
    String? userIntent,
  }) async {
    final trimmed = partialLine.trim();
    if (trimmed.isEmpty) {
      return const Left(AIFailure.invalidInput('Partial command line is empty'));
    }

    try {
      final available = await _service.isAvailable();
      if (!available) {
        if (_config.mode == AiMode.local) {
          return const Left(AIFailure.modelNotLoaded());
        }
        return const Left(AIFailure.providerUnavailable());
      }

      if (!_isServiceAllowedForConfig(_config.mode, _service.privacyMode)) {
        return const Left(AIFailure.providerUnavailable());
      }

      final prompt = _buildPrompt(
        partialLine: trimmed,
        context: context,
        userIntent: userIntent,
      );
      final suggestion = await _service.generateCommand(prompt);
      return Right(_mapSuggestion(suggestion, _service.privacyMode));
    } on AiNotConfiguredException {
      return const Left(AIFailure.providerUnavailable());
    } on AiServiceException catch (error) {
      return Left(_mapServiceException(error));
    } on Exception catch (error) {
      return Left(AIFailure.inferenceError(error.toString()));
    }
  }

  // @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine
  String _buildPrompt({
    required String partialLine,
    required ShellContext context,
    String? userIntent,
  }) {
    final buffer = StringBuffer()
      ..writeln('You are completing or refining an in-progress shell command.')
      ..writeln("Preserve the user's intent and improve the current line only when useful.")
      ..writeln('Return a command on the first line and a short explanation on the second line.')
      ..writeln('Current partial line: $partialLine')
      ..writeln('Shell: ${context.shell}')
      ..writeln('OS: ${context.os}');

    if (context.cwd != null && context.cwd!.isNotEmpty) {
      buffer.writeln('Current directory: ${context.cwd}');
    }
    if (context.availableCommands.isNotEmpty) {
      buffer.writeln(
        'Available commands: ${context.availableCommands.join(', ')}',
      );
    }
    if (context.recentCommands.isNotEmpty) {
      buffer.writeln(
        'Recent commands: ${context.recentCommands.take(5).join(', ')}',
      );
    }
    if (userIntent != null && userIntent.trim().isNotEmpty) {
      buffer.writeln('User intent: ${userIntent.trim()}');
    }

    buffer.write('Complete or refine the command.');
    return buffer.toString();
  }

  // @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine
  CommandSuggestion _mapSuggestion(
    AiSuggestion suggestion,
    AiPrivacyMode privacyMode,
  ) {
    return CommandSuggestion(
      command: suggestion.command,
      explanation: suggestion.explanation,
      confidence: suggestion.confidence,
      privacyMode: privacyMode,
      alternatives: suggestion.alternatives,
    );
  }

  // @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine
  AIFailure _mapServiceException(AiServiceException error) {
    switch (error.code) {
      case 'network':
      case 'timeout':
        return AIFailure.networkError(error.message);
      case 'rate_limit':
        return const AIFailure.rateLimited();
      case 'model_not_found':
      case 'model_not_loaded':
        return const AIFailure.modelNotLoaded();
      case 'unavailable':
      case 'invalid_key':
        return const AIFailure.providerUnavailable();
      default:
        return AIFailure.inferenceError(error.message);
    }
  }

  // @telos L1:function:lib/features/ai/domain/usecases:completeCommandLine
  bool _isServiceAllowedForConfig(AiMode mode, AiPrivacyMode privacyMode) {
    return switch (mode) {
      AiMode.local => privacyMode == AiPrivacyMode.local,
      AiMode.cloud => privacyMode == AiPrivacyMode.cloud,
      AiMode.remote => privacyMode == AiPrivacyMode.remote,
      AiMode.unconfigured => false,
    };
  }
}
