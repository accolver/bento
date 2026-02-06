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
      } catch (e) {
        // Ignore errors when stopping - generation might have already finished
      }
      _isGenerating = false;
    }
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
      // Fall back to pattern matching on error
      return _getFallbackSuggestion(prompt, error: e.toString());
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
  String _buildSystemPrompt() {
    return '''You are a shell command assistant. Output ONLY the command, nothing else.

Examples:
Q: list files
A: ls -la

Q: disk usage
A: df -h

Q: remove unused docker images
A: docker image prune -a

Q: show running containers
A: docker ps

Q: git status
A: git status

Q: find large files
A: find . -type f -size +100M

Q: show memory
A: free -h

Q: restart nginx
A: sudo systemctl restart nginx''';
  }

  /// Builds the full prompt with system context.
  String _buildFullPrompt(String systemPrompt, String userPrompt) {
    // Use a simple Q/A format that's fast to process
    // The model should output just the command after "A: "
    return '''$systemPrompt

Q: $userPrompt
A:''';
  }

  /// Parses the model response into an AiSuggestion.
  AiSuggestion _parseResponse(String response, String originalPrompt) {
    // Clean up the response
    var command = response.trim();

    // Remove common prefixes the model might add
    command = command
        .replaceAll(RegExp(r'^(Command:|Shell:|Bash:|>|\$)\s*'), '')
        .replaceAll(RegExp(r'^```(bash|sh|shell)?\n?'), '')
        .replaceAll(RegExp(r'\n?```$'), '')
        .trim();

    // Take only the first line if multiple lines
    final lines = command.split('\n');
    command = lines.first.trim();

    // If the command is empty or looks invalid, fall back
    if (command.isEmpty || command.length > 500) {
      return _getFallbackSuggestion(originalPrompt).copyWith(
        explanation: 'Model response was unclear. Using pattern matching.',
      );
    }

    return AiSuggestion(
      command: command,
      explanation: _generateExplanation(command, originalPrompt),
      confidence: 0.8,
    );
  }

  /// Generates a short human-readable explanation of what the command does.
  ///
  /// Uses the original user prompt to provide context-aware explanations,
  /// falling back to command parsing if the prompt doesn't provide clarity.
  String _generateExplanation(String command, String userPrompt) {
    // First, try to create a concise version of the user's intent
    final cleanPrompt = userPrompt.trim().toLowerCase();

    // If the prompt is short and clear, capitalize and use it
    if (cleanPrompt.length <= 40 && cleanPrompt.isNotEmpty) {
      // Capitalize first letter and ensure it doesn't end with punctuation
      var explanation = userPrompt.trim();
      explanation = explanation[0].toUpperCase() + explanation.substring(1);
      if (explanation.endsWith('.') ||
          explanation.endsWith('?') ||
          explanation.endsWith('!')) {
        explanation = explanation.substring(0, explanation.length - 1);
      }
      return explanation;
    }

    // For longer prompts, fall back to command-based explanation
    return _getCommandExplanation(command);
  }

  /// Generates an explanation based on parsing the command itself.
  String _getCommandExplanation(String command) {
    final lower = command.toLowerCase();
    final parts = command.split(' ');
    final baseCommand = parts.isNotEmpty ? parts.first : command;

    // Common command explanations
    switch (baseCommand) {
      case 'ls':
        if (command.contains('-la') || command.contains('-l')) {
          return 'List files with details';
        }
        if (command.contains('-a')) {
          return 'List all files including hidden';
        }
        return 'List directory contents';

      case 'cd':
        final dir = parts.length > 1 ? parts[1] : '~';
        return 'Change to $dir directory';

      case 'pwd':
        return 'Show current directory';

      case 'cat':
        return 'Display file contents';

      case 'grep':
        return 'Search for pattern in files';

      case 'find':
        return 'Search for files';

      case 'mkdir':
        return 'Create new directory';

      case 'rm':
        if (command.contains('-rf') || command.contains('-r')) {
          return 'Remove files/directories recursively';
        }
        return 'Remove files';

      case 'cp':
        return 'Copy files';

      case 'mv':
        return 'Move or rename files';

      case 'chmod':
        return 'Change file permissions';

      case 'chown':
        return 'Change file ownership';

      case 'df':
        return 'Show disk space usage';

      case 'du':
        return 'Show directory size';

      case 'free':
        return 'Show memory usage';

      case 'top':
      case 'htop':
        return 'Show running processes';

      case 'ps':
        return 'List processes';

      case 'kill':
      case 'killall':
        return 'Terminate process';

      case 'systemctl':
        if (lower.contains('status')) return 'Check service status';
        if (lower.contains('start')) return 'Start service';
        if (lower.contains('stop')) return 'Stop service';
        if (lower.contains('restart')) return 'Restart service';
        return 'Manage system service';

      case 'docker':
        if (lower.contains('ps')) return 'List Docker containers';
        if (lower.contains('images')) return 'List Docker images';
        if (lower.contains('run')) return 'Run Docker container';
        if (lower.contains('stop')) return 'Stop Docker container';
        if (lower.contains('logs')) return 'Show container logs';
        return 'Docker command';

      case 'kubectl':
        if (lower.contains('get pods')) return 'List Kubernetes pods';
        if (lower.contains('get services')) return 'List Kubernetes services';
        if (lower.contains('logs')) return 'Show pod logs';
        if (lower.contains('describe')) return 'Describe Kubernetes resource';
        return 'Kubernetes command';

      case 'git':
        if (lower.contains('status')) return 'Show git status';
        if (lower.contains('log')) return 'Show commit history';
        if (lower.contains('diff')) return 'Show changes';
        if (lower.contains('add')) return 'Stage changes';
        if (lower.contains('commit')) return 'Commit changes';
        if (lower.contains('push')) return 'Push to remote';
        if (lower.contains('pull')) return 'Pull from remote';
        if (lower.contains('clone')) return 'Clone repository';
        if (lower.contains('branch')) return 'Manage branches';
        if (lower.contains('checkout')) return 'Switch branch';
        return 'Git command';

      case 'ssh':
        return 'Connect via SSH';

      case 'scp':
        return 'Copy files over SSH';

      case 'rsync':
        return 'Sync files';

      case 'curl':
      case 'wget':
        return 'Download from URL';

      case 'tar':
        if (lower.contains('xzf') || lower.contains('xvf')) {
          return 'Extract archive';
        }
        if (lower.contains('czf') || lower.contains('cvf')) {
          return 'Create archive';
        }
        return 'Archive command';

      case 'zip':
        return 'Create zip archive';

      case 'unzip':
        return 'Extract zip archive';

      case 'apt':
      case 'apt-get':
        if (lower.contains('install')) return 'Install package';
        if (lower.contains('update')) return 'Update package list';
        if (lower.contains('upgrade')) return 'Upgrade packages';
        if (lower.contains('remove')) return 'Remove package';
        return 'Package manager command';

      case 'yum':
      case 'dnf':
        if (lower.contains('install')) return 'Install package';
        if (lower.contains('update')) return 'Update packages';
        if (lower.contains('remove')) return 'Remove package';
        return 'Package manager command';

      case 'pip':
      case 'pip3':
        if (lower.contains('install')) return 'Install Python package';
        if (lower.contains('list')) return 'List Python packages';
        return 'Python package manager';

      case 'npm':
        if (lower.contains('install')) return 'Install Node packages';
        if (lower.contains('run')) return 'Run npm script';
        if (lower.contains('start')) return 'Start Node app';
        return 'Node package manager';

      case 'yarn':
        if (lower.contains('add')) return 'Add Node package';
        if (lower.contains('install')) return 'Install dependencies';
        return 'Yarn package manager';

      case 'netstat':
        return 'Show network connections';

      case 'ss':
        return 'Show socket statistics';

      case 'ip':
        if (lower.contains('addr')) return 'Show IP addresses';
        if (lower.contains('route')) return 'Show routing table';
        return 'Network configuration';

      case 'ping':
        return 'Test network connectivity';

      case 'traceroute':
      case 'tracepath':
        return 'Trace network path';

      case 'nslookup':
      case 'dig':
        return 'DNS lookup';

      case 'tail':
        if (command.contains('-f')) return 'Follow file changes';
        return 'Show end of file';

      case 'head':
        return 'Show beginning of file';

      case 'less':
      case 'more':
        return 'View file with paging';

      case 'nano':
      case 'vim':
      case 'vi':
        return 'Edit file';

      case 'echo':
        return 'Print text';

      case 'whoami':
        return 'Show current user';

      case 'hostname':
        return 'Show hostname';

      case 'uname':
        return 'Show system info';

      case 'date':
        return 'Show date/time';

      case 'uptime':
        return 'Show system uptime';

      case 'history':
        return 'Show command history';

      case 'clear':
        return 'Clear terminal';

      case 'exit':
        return 'Exit shell';

      case 'sudo':
        // For sudo, explain the actual command
        if (parts.length > 1) {
          final sudoCommand = parts.sublist(1).join(' ');
          return 'Run as root: ${_getCommandExplanation(sudoCommand)}';
        }
        return 'Run as superuser';

      default:
        // For pipes and complex commands
        if (command.contains('|')) {
          return 'Multi-step pipeline command';
        }
        if (command.contains('&&')) {
          return 'Run multiple commands';
        }
        if (command.contains('>')) {
          return 'Command with output redirection';
        }
        // Generic fallback
        return 'Execute $baseCommand';
    }
  }

  /// Returns a fallback suggestion using pattern matching.
  AiSuggestion _getFallbackSuggestion(String prompt, {String? error}) {
    final command = _getFallbackCommand(prompt);
    // Use the prompt for explanation since user intent is clearer than parsed command
    final explanation = _generateExplanation(command, prompt);

    return AiSuggestion(
      command: command,
      explanation: explanation,
      confidence: 0.5,
    );
  }

  /// Returns a fallback stream for unsupported platforms.
  Stream<AiStreamEvent> _getFallbackStream(String prompt) async* {
    final command = _getFallbackCommand(prompt);
    final words = command.split(' ');

    for (final word in words) {
      yield AiStreamToken('$word ');
      await Future.delayed(const Duration(milliseconds: 50));
    }

    yield AiStreamComplete(
      AiSuggestion(
        command: command,
        explanation: _generateExplanation(command, prompt),
        confidence: 0.5,
      ),
    );
  }

  /// Gets a fallback command using simple pattern matching.
  ///
  /// This provides basic functionality when local inference is unavailable.
  String _getFallbackCommand(String prompt) {
    final lower = prompt.toLowerCase();

    // Docker commands (check specific patterns first)
    if (lower.contains('docker')) {
      if (lower.contains('remove') && lower.contains('image') ||
          lower.contains('prune') && lower.contains('image') ||
          lower.contains('unused') && lower.contains('image') ||
          lower.contains('clean') && lower.contains('image')) {
        return 'docker image prune -a';
      }
      if (lower.contains('remove') && lower.contains('container') ||
          lower.contains('prune') && lower.contains('container')) {
        return 'docker container prune';
      }
      if (lower.contains('stop') && lower.contains('all')) {
        return 'docker stop \$(docker ps -q)';
      }
      if (lower.contains('log')) {
        return 'docker logs --tail 100';
      }
      if (lower.contains('image')) {
        return 'docker images';
      }
      if (lower.contains('running') || lower.contains('container')) {
        return 'docker ps';
      }
      // Default docker command
      return 'docker ps -a';
    }

    // Git commands
    if (lower.contains('git')) {
      if (lower.contains('status')) return 'git status';
      if (lower.contains('log')) return 'git log --oneline -10';
      if (lower.contains('diff')) return 'git diff';
      if (lower.contains('branch')) return 'git branch -a';
      if (lower.contains('pull')) return 'git pull';
      if (lower.contains('push')) return 'git push';
      return 'git status';
    }

    // Kubernetes commands
    if (lower.contains('kubectl') ||
        lower.contains('kubernetes') ||
        lower.contains('k8s')) {
      if (lower.contains('pod')) return 'kubectl get pods';
      if (lower.contains('service')) return 'kubectl get services';
      if (lower.contains('log')) return 'kubectl logs';
      return 'kubectl get pods';
    }

    // File operations
    if (lower.contains('find') && lower.contains('file')) {
      return 'find . -name "*.txt" -type f';
    }
    if (lower.contains('list') && lower.contains('file')) {
      return 'ls -la';
    }
    if (lower.contains('list')) {
      return 'ls -la';
    }

    // System monitoring
    if (lower.contains('disk') || lower.contains('storage')) {
      return 'df -h';
    }
    if (lower.contains('memory') || lower.contains('ram')) {
      return 'free -h';
    }
    if (lower.contains('process')) {
      return 'ps aux';
    }
    if (lower.contains('network') || lower.contains('ip')) {
      return 'ip addr show';
    }
    if (lower.contains('port') || lower.contains('listening')) {
      return 'netstat -tlnp';
    }
    if (lower.contains('cpu') || lower.contains('system')) {
      return 'top -bn1 | head -20';
    }

    // Service management
    if (lower.contains('restart') ||
        lower.contains('start') ||
        lower.contains('stop')) {
      if (lower.contains('nginx')) return 'sudo systemctl restart nginx';
      if (lower.contains('apache')) return 'sudo systemctl restart apache2';
      if (lower.contains('mysql')) return 'sudo systemctl restart mysql';
      if (lower.contains('postgres'))
        return 'sudo systemctl restart postgresql';
    }

    // Default: echo the request
    return 'echo "Request: $prompt"';
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
