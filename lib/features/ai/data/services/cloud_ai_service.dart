// @telos L1:function:lib/features/ai/data/services:cloud_ai_service

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/entities/ai_config.dart';
import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/prompt_templates.dart';
import '../repositories/ai_config_repository.dart';

/// Cloud AI service using OpenRouter API.
///
/// Implements [AiService] interface for cloud-based AI command generation.
/// Uses OpenRouter as a unified gateway to multiple LLM providers
/// (Claude, GPT-4, Gemini, Llama, etc.).
///
/// **Privacy**: Data is sent to external servers. Users must acknowledge
/// this during setup.
///
/// **API Format**: OpenAI-compatible chat completion API.
/// Endpoint: https://openrouter.ai/api/v1/chat/completions
class CloudAiService implements AiService {
  CloudAiService({
    required AiConfigRepository configRepository,
    required CloudAiProvider provider,
    Dio? dio,
    this.maxTokens = 256,
    this.temperature = 0.3,
  })  : _configRepository = configRepository,
        _provider = provider,
        _dio = dio ?? _createDefaultDio();

  final AiConfigRepository _configRepository;
  final CloudAiProvider _provider;
  final Dio _dio;

  /// Maximum tokens to generate.
  final int maxTokens;

  /// Temperature for generation (0.0 = deterministic, 1.0 = creative).
  final double temperature;

  /// OpenRouter API endpoint.
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Creates a default Dio instance with appropriate settings.
  static Dio _createDefaultDio() {
    return Dio(
      BaseOptions(
        baseUrl: 'https://openrouter.ai/api/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  @override
  String get serviceName => 'Cloud (${_providerDisplayName})';

  String get _providerDisplayName {
    switch (_provider) {
      case CloudAiProvider.claude:
        return 'Claude';
      case CloudAiProvider.gpt4oMini:
        return 'GPT-4o Mini';
      case CloudAiProvider.llama3:
        return 'Llama 3';
      case CloudAiProvider.gemini:
        return 'Gemini';
    }
  }

  @override
  AiPrivacyMode get privacyMode => AiPrivacyMode.cloud;

  @override
  Future<bool> isAvailable() async {
    final apiKey = await _configRepository.getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  @override
  Future<void> dispose() async {
    _dio.close();
  }

  @override
  Future<AiSuggestion> generateCommand(String prompt) async {
    final apiKey = await _getApiKeyOrThrow();

    final messages = _buildMessages(prompt);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': _provider.modelId,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'stream': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://bento.app',
            'X-Title': 'Bento Terminal',
          },
        ),
      );

      return _parseResponse(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(String prompt) async* {
    final String apiKey;
    try {
      apiKey = await _getApiKeyOrThrow();
    } on AiServiceException catch (e) {
      yield AiStreamError(e.message, code: e.code, originalError: e);
      return;
    }
    final messages = _buildMessages(prompt);

    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': _provider.modelId,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'stream': true,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'HTTP-Referer': 'https://bento.app',
            'X-Title': 'Bento Terminal',
          },
          responseType: ResponseType.stream,
        ),
      );

      final StringBuffer commandBuffer = StringBuffer();

      await for (final chunk in response.data!.stream) {
        final lines = utf8.decode(chunk).split('\n');

        for (final line in lines) {
          if (line.isEmpty || !line.startsWith('data: ')) continue;

          final data = line.substring(6); // Remove 'data: ' prefix

          if (data == '[DONE]') {
            // Stream complete, yield final suggestion
            final response = commandBuffer.toString().trim();
            final (command, explanation) =
                _parseCommandAndExplanation(response);
            yield AiStreamComplete(
              AiSuggestion(
                command: command,
                explanation: explanation,
                confidence: 0.85,
              ),
            );
            return;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;

            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;

              if (content != null && content.isNotEmpty) {
                commandBuffer.write(content);
                yield AiStreamToken(content);
              }
            }
          } on FormatException {
            // Ignore malformed JSON chunks
          }
        }
      }

      // If we reach here without [DONE], still complete with what we have
      final finalText = commandBuffer.toString().trim();
      if (finalText.isNotEmpty) {
        final (command, explanation) = _parseCommandAndExplanation(finalText);
        yield AiStreamComplete(
          AiSuggestion(
            command: command,
            explanation: explanation,
            confidence: 0.85,
          ),
        );
      } else {
        yield const AiStreamError('No response received from AI service');
      }
    } on DioException catch (e) {
      yield AiStreamError(
        _handleDioError(e).message,
        code: _getErrorCode(e),
        originalError: e,
      );
    }
  }

  /// Builds the messages array for the chat completion API.
  List<Map<String, String>> _buildMessages(String userPrompt) {
    final template = PromptTemplates.commandGeneration;

    return [
      {'role': 'system', 'content': template.system},
      {'role': 'user', 'content': template.user(userPrompt)},
    ];
  }

  /// Parses the non-streaming API response into an AiSuggestion.
  AiSuggestion _parseResponse(Map<String, dynamic> response) {
    final choices = response['choices'] as List<dynamic>?;

    if (choices == null || choices.isEmpty) {
      throw const AiServiceException(
        'No response from AI service',
        code: 'empty_response',
      );
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null || content.isEmpty) {
      throw const AiServiceException(
        'Empty response from AI service',
        code: 'empty_content',
      );
    }

    // Parse command and explanation from response
    final (command, explanation) = _parseCommandAndExplanation(content);

    return AiSuggestion(
      command: command,
      explanation: explanation,
      confidence: 0.85, // Cloud models are generally reliable
    );
  }

  /// Parses the "COMMAND | EXPLANATION" format from LLM response.
  ///
  /// Returns a tuple of (command, explanation).
  (String, String) _parseCommandAndExplanation(String content) {
    var text = content.trim();

    // Remove markdown code blocks if present
    if (text.startsWith('```')) {
      final lines = text.split('\n');
      if (lines.length > 1) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.trim() == '```') {
        lines.removeLast();
      }
      text = lines.join('\n').trim();
    }

    // Take only the first line if there are multiple
    final firstLine = text.split('\n').first.trim();

    // Remove any leading $ or # prompt characters
    var cleanLine = firstLine;
    if (cleanLine.startsWith(r'$ ')) {
      cleanLine = cleanLine.substring(2);
    }
    if (cleanLine.startsWith('# ')) {
      cleanLine = cleanLine.substring(2);
    }

    // Parse command and explanation from "COMMAND | EXPLANATION" format
    String command;
    String explanation;

    if (cleanLine.contains('|')) {
      final parts = cleanLine.split('|');
      command = parts[0].trim();
      explanation = parts.length > 1 ? parts.sublist(1).join('|').trim() : '';
    } else {
      command = cleanLine;
      explanation = '';
    }

    // Default explanation if none provided
    if (explanation.isEmpty) {
      explanation = 'Generated command';
    }

    return (command, explanation);
  }

  /// Gets the API key or throws if not available.
  Future<String> _getApiKeyOrThrow() async {
    final apiKey = await _configRepository.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw const AiServiceException(
        'API key not configured. Please set up cloud AI in settings.',
        code: 'no_api_key',
      );
    }

    return apiKey;
  }

  /// Handles Dio errors and converts them to AiServiceException.
  AiServiceException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AiServiceException(
          'Connection timeout. Please check your network.',
          code: 'timeout',
          originalError: e,
          isRetryable: true,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (statusCode == 401) {
          return AiServiceException(
            'Invalid API key. Please check your OpenRouter key.',
            code: 'invalid_key',
            originalError: e,
          );
        }

        if (statusCode == 429) {
          // Parse retry-after if available
          final retryAfter = e.response?.headers.value('retry-after');
          final message = retryAfter != null
              ? 'Rate limited. Please wait ${retryAfter}s and try again.'
              : 'Rate limited. Please wait and try again.';

          return AiServiceException(
            message,
            code: 'rate_limit',
            originalError: e,
            isRetryable: true,
          );
        }

        if (statusCode == 503) {
          return AiServiceException(
            'AI service temporarily unavailable. Try a different model.',
            code: 'service_unavailable',
            originalError: e,
            isRetryable: true,
          );
        }

        // Try to extract error message from response
        String? errorMessage;
        if (data is Map<String, dynamic>) {
          final error = data['error'];
          if (error is Map<String, dynamic>) {
            errorMessage = error['message'] as String?;
          } else if (error is String) {
            errorMessage = error;
          }
        }

        return AiServiceException(
          errorMessage ?? 'API error: $statusCode',
          code: 'api_error',
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return AiServiceException(
          'Network error. Please check your connection.',
          code: 'network',
          originalError: e,
          isRetryable: true,
        );

      case DioExceptionType.cancel:
        return AiServiceException(
          'Request cancelled',
          code: 'cancelled',
          originalError: e,
        );

      default:
        return AiServiceException(
          'Unexpected error: ${e.message}',
          code: 'unknown',
          originalError: e,
        );
    }
  }

  /// Gets error code string from DioException.
  String? _getErrorCode(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'timeout';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) return 'invalid_key';
        if (statusCode == 429) return 'rate_limit';
        if (statusCode == 503) return 'service_unavailable';
        return 'api_error';
      case DioExceptionType.connectionError:
        return 'network';
      case DioExceptionType.cancel:
        return 'cancelled';
      default:
        return 'unknown';
    }
  }
}
