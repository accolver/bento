// @telos L1:function:lib/features/ai/data/services:local_ai_service

import 'dart:async';
import 'dart:io';

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
    this.contextSize = 2048,
    this.maxTokens = 64, // Commands are short, limit for speed
    this.temperature = 0.1, // Lower temperature for more deterministic output
    this.nThreads = 4,
    this.useGpu = true,
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
  final _generationLock = Completer<void>()..complete();

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
    if (_isModelLoaded) return;
    if (!_isPlatformSupported) return;

    _controller ??= LlamaController();

    await _controller!.loadModel(
      modelPath: _modelPath,
      threads: nThreads,
      contextSize: contextSize,
      gpuLayers: useGpu ? 99 : 0,
    );

    _isModelLoaded = true;
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

  /// Waits for any in-progress generation to complete.
  ///
  /// Call this before performing actions that might conflict with
  /// native LLM operations (like executing a command).
  Future<void> waitForCompletion() async {
    // If generation is in progress, wait a bit for it to stabilize
    if (_isGenerating) {
      // Try to stop gracefully
      await stopGeneration();
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

    // Stop any in-progress generation first
    await stopGeneration();

    try {
      _isGenerating = true;
      await _ensureModelLoaded();

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

    // Stop any in-progress generation first
    await stopGeneration();

    try {
      _isGenerating = true;
      await _ensureModelLoaded();

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
    }
  }

  @override
  Future<void> dispose() async {
    await stopGeneration();
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isModelLoaded = false;
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
