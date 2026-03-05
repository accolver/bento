// @telos L1:function:lib/features/ai/data/services:local_ai_service

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';

/// Local AI service for on-device inference using llama.cpp.
///
/// This service provides complete privacy by running LLM inference
/// entirely on the device with no network connection required.
///
/// **Platform Support**:
/// - Android: Full support via llama_flutter_android
/// - iOS: Not yet supported (placeholder returns helpful message)
///
/// **Features**:
/// - GGUF model support
/// - Streaming token generation
/// - Configurable parameters (temperature, context size, etc.)
/// - GPU acceleration where available
/// - Automatic cancellation of in-flight requests
class LocalAiService implements AiService {
  LocalAiService({
    required String modelPath,
    this.contextSize = 512, // Small context to minimize RAM usage
    this.maxTokens = 64, // Commands are short, limit for speed
    this.temperature = 0.1, // Lower temperature for more deterministic output
    this.nThreads = 2, // Fewer threads = less memory pressure
    this.useGpu = false, // Disabled for compatibility
  }) : _modelPath = modelPath;

  final String _modelPath;

  /// Context window size in tokens.
  final int contextSize;

  /// Maximum tokens to generate.
  final int maxTokens;

  /// Temperature for generation (0.0 = deterministic, 1.0 = creative).
  final double temperature;

  /// Number of CPU threads to use.
  final int nThreads;

  /// Whether to use GPU acceleration.
  final bool useGpu;

  /// Model name extracted from path for display.
  String? _modelName;

  /// The llama.cpp controller for Android.
  LlamaController? _controller;

  /// Whether the model has been loaded.
  bool _isModelLoaded = false;

  /// Whether a generation is currently in progress.
  bool _isGenerating = false;

  /// Lock to prevent concurrent generation requests.
  Completer<void>? _generationLock;

  /// Whether we're on a supported platform (Android).
  bool get _isPlatformSupported => Platform.isAndroid;

  /// Whether a generation is currently in progress.
  bool get isGenerating => _isGenerating;

  @override
  String get serviceName {
    final name = _modelName ?? _extractModelName(_modelPath);
    return 'Local ($name)';
  }

  @override
  AiPrivacyMode get privacyMode => AiPrivacyMode.local;

  @override
  Future<bool> isAvailable() async {
    // Check if model file exists
    final file = File(_modelPath);
    if (!await file.exists()) {
      return false;
    }

    _modelName = _extractModelName(_modelPath);

    // On unsupported platforms, return true but operations will fall back
    if (!_isPlatformSupported) {
      return true;
    }

    // Try to initialize the controller if not already done
    try {
      if (_controller == null) {
        _controller = LlamaController();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Loads the model into memory.
  ///
  /// This must be called before generating commands.
  /// Loading can take several seconds depending on model size.
  Future<void> _ensureModelLoaded() async {
    if (_isModelLoaded) {
      if (kDebugMode) {
        debugPrint('[LocalAiService] Model already loaded (flag check)');
      }
      return;
    }
    if (!_isPlatformSupported) return;

    _controller ??= LlamaController();

    try {
      // Don't pass gpuLayers - let the library use its default
      // Some devices have issues with GPU acceleration
      await _controller!.loadModel(
        modelPath: _modelPath,
        threads: nThreads,
        contextSize: contextSize,
      );

      _isModelLoaded = true;
      if (kDebugMode) {
        debugPrint('[LocalAiService] Model loaded successfully');
      }
    } on StateError catch (e) {
      // Handle "Model already loaded" error from the library
      if (e.message.contains('already loaded')) {
        if (kDebugMode) {
          debugPrint('[LocalAiService] Model was already loaded in native layer');
        }
        _isModelLoaded = true;
        return;
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalAiService] Model load failed: $e');
      }
      rethrow;
    }
  }

  /// Stops any in-progress generation.
  ///
  /// This should be called before starting a new generation to avoid
  /// the "already generating" error.
  Future<void> stopGeneration() async {
    if (!_isPlatformSupported || _controller == null) return;

    if (_isGenerating) {
      try {
        await _controller!.stop();
        // Give native resources time to clean up
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Ignore errors when stopping - generation might have already finished
      }
      _isGenerating = false;
    }
  }

  /// Acquires the generation lock to prevent concurrent generation.
  /// 
  /// Call this before starting any generation. The lock will be released
  /// automatically when generation completes.
  Future<void> _acquireGenerationLock() async {
    // Wait for any existing generation to complete
    if (_generationLock != null && !_generationLock!.isCompleted) {
      await _generationLock!.future;
    }
    // Create a new lock for this generation
    _generationLock = Completer<void>();
  }

  /// Releases the generation lock.
  void _releaseGenerationLock() {
    if (_generationLock != null && !_generationLock!.isCompleted) {
      _generationLock!.complete();
    }
  }

  /// Waits for any in-progress generation to complete.
  ///
  /// Call this before performing actions that might conflict with
  /// native LLM operations (like executing a command).
  Future<void> waitForCompletion() async {
    // Wait for the lock if generation is in progress
    if (_generationLock != null && !_generationLock!.isCompleted) {
      await _generationLock!.future;
    }
    // Additional delay to let native resources settle
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<AiSuggestion> generateCommand(String prompt) async {
    // Verify model exists
    final file = File(_modelPath);
    if (!await file.exists()) {
      throw AiServiceException(
        'Model file not found: $_modelPath',
        code: 'model_not_found',
      );
    }

    _modelName = _extractModelName(_modelPath);

    // On unsupported platforms, return fallback
    if (!_isPlatformSupported) {
      return _getFallbackSuggestion(prompt);
    }

    // Acquire generation lock to prevent concurrent access
    await _acquireGenerationLock();

    try {
      _isGenerating = true;
      await _ensureModelLoaded();

      // Clear context before each generation to avoid KV cache overflow.
      // We use single-shot generation (not chat), so we don't need history.
      await _controller!.clearContext();

      // Build the prompt for command generation
      final systemPrompt = _buildSystemPrompt();
      final fullPrompt = _buildFullPrompt(systemPrompt, prompt);

      // Collect all tokens
      final buffer = StringBuffer();
      final completer = Completer<void>();

      final subscription = _controller!
          .generate(
        prompt: fullPrompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.1,
      )
          .listen(
        (token) {
          buffer.write(token);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      await completer.future;
      await subscription.cancel();

      final response = buffer.toString().trim();
      return _parseResponse(response, prompt);
    } catch (e) {
      // Fall back on error
      return _getFallbackSuggestion(prompt);
    } finally {
      _isGenerating = false;
      _releaseGenerationLock();
    }
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(String prompt) async* {
    // Verify model exists
    final file = File(_modelPath);
    if (!await file.exists()) {
      yield AiStreamError(
        'Model file not found: $_modelPath',
        code: 'model_not_found',
      );
      return;
    }

    _modelName = _extractModelName(_modelPath);

    // On unsupported platforms, simulate streaming with fallback
    if (!_isPlatformSupported) {
      yield* _getFallbackStream(prompt);
      return;
    }

    // Acquire generation lock to prevent concurrent access
    await _acquireGenerationLock();

    try {
      _isGenerating = true;
      await _ensureModelLoaded();

      // Clear context before each generation to avoid KV cache overflow.
      // We use single-shot generation (not chat), so we don't need history.
      await _controller!.clearContext();

      final systemPrompt = _buildSystemPrompt();
      final fullPrompt = _buildFullPrompt(systemPrompt, prompt);

      final buffer = StringBuffer();

      await for (final token in _controller!.generate(
        prompt: fullPrompt,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.1,
      )) {
        buffer.write(token);
        yield AiStreamToken(token);
      }

      final response = buffer.toString().trim();
      final suggestion = _parseResponse(response, prompt);
      yield AiStreamComplete(suggestion);
    } catch (e) {
      yield AiStreamError(
        'Local AI generation failed: $e',
        code: 'generation_error',
      );
    } finally {
      _isGenerating = false;
      _releaseGenerationLock();
    }
  }

  @override
  Future<void> dispose() async {
    await stopGeneration();
    
    // Release any pending generation lock
    _releaseGenerationLock();
    
    // Clean up native resources
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isModelLoaded = false;
    }
  }

  @override
  Future<String> summarizeOutput(String command, String output) async {
    if (kDebugMode) {
      debugPrint('[LocalAiService] summarizeOutput called');
      debugPrint('[LocalAiService] Model path: $_modelPath');
    }

    // Verify model exists
    final file = File(_modelPath);
    if (!await file.exists()) {
      if (kDebugMode) {
        debugPrint('[LocalAiService] Model file not found!');
      }
      throw AiServiceException(
        'Model file not found: $_modelPath',
        code: 'model_not_found',
      );
    }
    if (kDebugMode) {
      debugPrint('[LocalAiService] Model file exists');
    }

    // On unsupported platforms, throw an error
    if (!_isPlatformSupported) {
      if (kDebugMode) {
        debugPrint(
            '[LocalAiService] Platform not supported: ${Platform.operatingSystem}');
      }
      throw AiServiceException(
        'Local AI not available on ${Platform.operatingSystem}',
        code: 'unsupported_platform',
      );
    }
    if (kDebugMode) {
      debugPrint('[LocalAiService] Platform supported');
    }

    // Acquire generation lock to prevent concurrent access
    await _acquireGenerationLock();
    if (kDebugMode) {
      debugPrint('[LocalAiService] Acquired generation lock');
    }

    try {
      _isGenerating = true;
      if (kDebugMode) {
        debugPrint('[LocalAiService] Loading model...');
      }
      await _ensureModelLoaded();
      if (kDebugMode) {
        debugPrint(
            '[LocalAiService] Model loaded, isModelLoaded=$_isModelLoaded');
      }

      // Clear context before generation
      if (kDebugMode) {
        debugPrint('[LocalAiService] Clearing context...');
      }
      await _controller!.clearContext();
      if (kDebugMode) {
        debugPrint('[LocalAiService] Context cleared');
      }

      // Truncate output if too long (keep first 500 chars for context)
      final truncatedOutput =
          output.length > 500 ? '${output.substring(0, 500)}...' : output;

      // Build summarization prompt - be very explicit about summarizing the OUTPUT not the command
      final prompt = '''The user ran "$command" and got this output:

$truncatedOutput

Briefly describe what this output shows (1-2 sentences):''';

      if (kDebugMode) {
        debugPrint('[LocalAiService] Starting generation...');
        debugPrint('[LocalAiService] Prompt length: ${prompt.length}');
      }

      // Collect all tokens
      final buffer = StringBuffer();
      final completer = Completer<void>();

      final subscription = _controller!
          .generate(
        prompt: prompt,
        maxTokens: 64,
        temperature: 0.3,
        topP: 0.9,
        topK: 40,
        repeatPenalty: 1.1,
      )
          .listen(
        (token) {
          buffer.write(token);
        },
        onDone: () {
          if (kDebugMode) {
            debugPrint(
                '[LocalAiService] Generation complete, tokens: ${buffer.length}');
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (Object error) {
          if (kDebugMode) {
            debugPrint('[LocalAiService] Generation error: $error');
          }
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      await completer.future;
      await subscription.cancel();

      final response = buffer.toString().trim();
      if (kDebugMode) {
        debugPrint('[LocalAiService] Raw response: $response');
      }

      // Clean up the response
      var summary = response
          .replaceAll(
              RegExp(r'^(Summary:|Output:)\s*', caseSensitive: false), '')
          .trim();

      // Take only the first 1-2 sentences
      final sentences = summary.split(RegExp(r'[.!?]\s+'));
      if (sentences.length > 2) {
        summary = '${sentences.take(2).join('. ')}.';
      }

      if (kDebugMode) {
        debugPrint('[LocalAiService] Final summary: $summary');
      }
      return summary.isEmpty ? 'No summary available.' : summary;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[LocalAiService] Exception during summarization: $e');
        debugPrint('[LocalAiService] Stack trace: $stackTrace');
      }
      // Re-throw so the UI can show the actual error
      throw AiServiceException(
        'Summarization failed: $e',
        code: 'summarization_error',
      );
    } finally {
      _isGenerating = false;
      _releaseGenerationLock();
    }
  }

  /// Builds the system prompt for command generation.
  ///
  /// The prompt asks for both a command and a short explanation.
  String _buildSystemPrompt() {
    return '''You are a shell command assistant. Output a command and brief explanation.

Format: COMMAND | EXPLANATION

Examples:
Q: list files
A: ls -la | List all files with details

Q: stop all docker containers
A: docker stop \$(docker ps -q) | Stop all running containers

Q: remove unused docker images
A: docker image prune -a | Remove all unused images

Q: find large files
A: find . -type f -size +100M | Find files larger than 100MB

Q: restart nginx
A: sudo systemctl restart nginx | Restart the nginx service''';
  }

  /// Builds the full prompt with system context.
  String _buildFullPrompt(String systemPrompt, String userPrompt) {
    return '''$systemPrompt

Q: $userPrompt
A:''';
  }

  /// Parses the model response into an AiSuggestion.
  ///
  /// Expects format: COMMAND | EXPLANATION
  AiSuggestion _parseResponse(String response, String originalPrompt) {
    var text = response.trim();

    // Remove common prefixes the model might add
    text = text
        .replaceAll(RegExp(r'^(Command:|Shell:|Bash:|>|\$)\s*'), '')
        .replaceAll(RegExp(r'^```(bash|sh|shell)?\n?'), '')
        .replaceAll(RegExp(r'\n?```$'), '')
        .trim();

    // Take only the first line if multiple lines
    final lines = text.split('\n');
    text = lines.first.trim();

    // Parse command and explanation from "COMMAND | EXPLANATION" format
    String command;
    String explanation;

    if (text.contains('|')) {
      final parts = text.split('|');
      command = parts[0].trim();
      explanation = parts.length > 1 ? parts.sublist(1).join('|').trim() : '';
    } else {
      // No pipe separator - treat whole thing as command
      command = text;
      explanation = '';
    }

    // Clean up command
    command = command
        .replaceAll(RegExp(r'^(Command:|Shell:|Bash:|>|\$)\s*'), '')
        .trim();

    // If the command is empty or looks invalid, fall back
    if (command.isEmpty || command.length > 500) {
      return _getFallbackSuggestion(originalPrompt);
    }

    // If no explanation was provided, generate a simple one
    if (explanation.isEmpty) {
      explanation = 'Execute command';
    }

    return AiSuggestion(
      command: command,
      explanation: explanation,
      confidence: 0.8,
    );
  }

  /// Returns a fallback suggestion when LLM is unavailable.
  ///
  /// Returns an error message prompting the user to download a model.
  AiSuggestion _getFallbackSuggestion(String prompt) {
    return AiSuggestion(
      command: '# AI model not available',
      explanation: 'Download an AI model in settings to generate commands',
      confidence: 0.0,
    );
  }

  /// Returns a fallback stream for unsupported platforms.
  Stream<AiStreamEvent> _getFallbackStream(String prompt) async* {
    yield const AiStreamError(
      'Local AI not available on this platform. Download an AI model in settings.',
      code: 'unsupported_platform',
    );
  }

  /// Extracts a display name from the model path.
  String _extractModelName(String path) {
    final filename = path.split('/').last;
    // Remove .gguf extension
    var name = filename.replaceAll('.gguf', '');
    // Clean up common quantization patterns
    name = name
        .replaceAll(RegExp(r'[-_]q[0-9]+_k_[ms]'), '')
        .replaceAll(RegExp(r'[-_]q[0-9]+_[0-9]'), '')
        .replaceAll(RegExp(r'[-_]q[0-9]+'), '');
    // Capitalize first letter
    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }
    return name.isEmpty ? 'Local Model' : name;
  }
}

/// Extension to add copyWith to AiSuggestion for internal use.
extension _AiSuggestionCopyWith on AiSuggestion {
  AiSuggestion copyWith({
    String? command,
    String? explanation,
    double? confidence,
    List<String>? alternatives,
  }) {
    return AiSuggestion(
      command: command ?? this.command,
      explanation: explanation ?? this.explanation,
      confidence: confidence ?? this.confidence,
      alternatives: alternatives ?? this.alternatives,
    );
  }
}
