// @telos L1:function:lib/features/ai/data/services:mock_ai_service

import 'dart:async';
import 'dart:math';

import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';

/// Mock AI service for UI development and testing.
///
/// Provides keyword-based command suggestions without actual AI processing.
/// This allows the UI to be built and tested before the real AI gateway
/// is implemented.
///
/// Implements [AiService] interface for compatibility with the AI gateway
/// abstraction layer.
class MockAiService implements AiService {
  MockAiService({
    this.minDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(milliseconds: 1500),
  });

  /// Minimum delay before returning a suggestion.
  final Duration minDelay;

  /// Maximum delay before returning a suggestion.
  final Duration maxDelay;

  final _random = Random();

  @override
  String get serviceName => 'Mock AI';

  @override
  AiPrivacyMode get privacyMode => AiPrivacyMode.local;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> dispose() async {
    // No resources to clean up for mock service
  }

  /// Command templates mapped to keywords.
  static const _commandTemplates = <String, _CommandTemplate>{
    // File operations
    'list': _CommandTemplate(
      command: 'ls -la',
      explanation: 'Lists all files including hidden ones with details',
      confidence: 0.95,
    ),
    'files': _CommandTemplate(
      command: 'ls -la',
      explanation: 'Lists all files including hidden ones with details',
      confidence: 0.90,
    ),
    'find': _CommandTemplate(
      command: 'find . -name "*.txt"',
      explanation:
          'Searches for files matching the pattern in current directory',
      confidence: 0.85,
    ),
    'search': _CommandTemplate(
      command: 'grep -r "pattern" .',
      explanation: 'Searches for text pattern recursively in current directory',
      confidence: 0.82,
    ),
    'delete': _CommandTemplate(
      command: 'rm -i filename',
      explanation: 'Removes file with confirmation prompt',
      confidence: 0.88,
    ),
    'remove': _CommandTemplate(
      command: 'rm -i filename',
      explanation: 'Removes file with confirmation prompt',
      confidence: 0.88,
    ),
    'copy': _CommandTemplate(
      command: 'cp -r source destination',
      explanation: 'Copies files or directories recursively',
      confidence: 0.90,
    ),
    'move': _CommandTemplate(
      command: 'mv source destination',
      explanation: 'Moves or renames files/directories',
      confidence: 0.92,
    ),

    // Disk operations
    'disk': _CommandTemplate(
      command: 'df -h',
      explanation: 'Shows disk space usage in human-readable format',
      confidence: 0.95,
    ),
    'space': _CommandTemplate(
      command: 'du -sh *',
      explanation: 'Shows size of each item in current directory',
      confidence: 0.88,
    ),
    'usage': _CommandTemplate(
      command: 'du -sh * | sort -h',
      explanation: 'Shows directory sizes sorted by size',
      confidence: 0.85,
    ),

    // Process operations
    'process': _CommandTemplate(
      command: 'ps aux',
      explanation: 'Lists all running processes with details',
      confidence: 0.92,
    ),
    'kill': _CommandTemplate(
      command: 'kill -9 PID',
      explanation: 'Forcefully terminates a process by its ID',
      confidence: 0.88,
    ),
    'running': _CommandTemplate(
      command: 'ps aux | grep process_name',
      explanation: 'Finds processes matching the name',
      confidence: 0.85,
    ),

    // Network operations
    'network': _CommandTemplate(
      command: 'netstat -tuln',
      explanation: 'Shows active network connections and listening ports',
      confidence: 0.88,
    ),
    'ports': _CommandTemplate(
      command: 'ss -tuln',
      explanation: 'Shows listening ports and connections',
      confidence: 0.90,
    ),
    'ping': _CommandTemplate(
      command: 'ping -c 4 hostname',
      explanation: 'Tests network connectivity with 4 packets',
      confidence: 0.95,
    ),
    'ip': _CommandTemplate(
      command: 'ip addr show',
      explanation: 'Shows IP addresses of all network interfaces',
      confidence: 0.92,
    ),

    // Docker operations
    'docker': _CommandTemplate(
      command: 'docker ps',
      explanation: 'Lists running Docker containers',
      confidence: 0.95,
    ),
    'containers': _CommandTemplate(
      command: 'docker ps -a',
      explanation: 'Lists all Docker containers including stopped ones',
      confidence: 0.92,
    ),
    'images': _CommandTemplate(
      command: 'docker images',
      explanation: 'Lists Docker images on the system',
      confidence: 0.95,
    ),

    // Kubernetes operations
    'pods': _CommandTemplate(
      command: 'kubectl get pods',
      explanation: 'Lists pods in the current namespace',
      confidence: 0.95,
    ),
    'services': _CommandTemplate(
      command: 'kubectl get services',
      explanation: 'Lists services in the current namespace',
      confidence: 0.92,
    ),
    'deployments': _CommandTemplate(
      command: 'kubectl get deployments',
      explanation: 'Lists deployments in the current namespace',
      confidence: 0.92,
    ),
    'logs': _CommandTemplate(
      command: 'kubectl logs pod-name',
      explanation: 'Shows logs from a specific pod',
      confidence: 0.88,
    ),

    // Git operations
    'git': _CommandTemplate(
      command: 'git status',
      explanation: 'Shows the current state of the repository',
      confidence: 0.95,
    ),
    'commit': _CommandTemplate(
      command: 'git commit -m "message"',
      explanation: 'Creates a commit with the specified message',
      confidence: 0.92,
    ),
    'branch': _CommandTemplate(
      command: 'git branch -a',
      explanation: 'Lists all branches including remote ones',
      confidence: 0.90,
    ),

    // System operations
    'memory': _CommandTemplate(
      command: 'free -h',
      explanation: 'Shows memory usage in human-readable format',
      confidence: 0.95,
    ),
    'cpu': _CommandTemplate(
      command: 'top -b -n 1 | head -20',
      explanation: 'Shows CPU and process information',
      confidence: 0.85,
    ),
    'uptime': _CommandTemplate(
      command: 'uptime',
      explanation: 'Shows how long the system has been running',
      confidence: 0.98,
    ),
    'date': _CommandTemplate(
      command: 'date',
      explanation: 'Shows current date and time',
      confidence: 0.98,
    ),
  };

  /// Keyword groups that should be matched together for better context.
  /// When multiple keywords from the same group are present, boost that group.
  static const _keywordGroups = <String, List<String>>{
    'docker': ['docker', 'containers', 'images'],
    'kubernetes': ['pods', 'services', 'deployments', 'kubectl', 'logs'],
    'git': ['git', 'commit', 'branch'],
    'files': ['list', 'files', 'find', 'search'],
  };

  /// Generates a command suggestion based on the input text.
  ///
  /// Matches keywords in the input and returns an appropriate suggestion.
  /// Uses contextual grouping to prioritize more specific matches.
  /// If no keywords match, returns a generic suggestion with lower confidence.
  @override
  Future<AiSuggestion> generateCommand(String input) async {
    // Simulate AI processing delay
    final delay = Duration(
      milliseconds: minDelay.inMilliseconds +
          _random.nextInt(maxDelay.inMilliseconds - minDelay.inMilliseconds),
    );
    await Future<void>.delayed(delay);

    // Normalize input for matching
    final normalizedInput = input.toLowerCase().trim();

    // First, check for keyword group matches (more context = better match)
    final groupScores = <String, int>{};
    for (final group in _keywordGroups.entries) {
      var score = 0;
      for (final keyword in group.value) {
        if (normalizedInput.contains(keyword)) {
          score++;
        }
      }
      if (score > 0) {
        groupScores[group.key] = score;
      }
    }

    // Find the group with the highest score (most keyword matches)
    String? bestGroup;
    var bestGroupScore = 0;
    for (final entry in groupScores.entries) {
      if (entry.value > bestGroupScore) {
        bestGroupScore = entry.value;
        bestGroup = entry.key;
      }
    }

    // Find matching template, prioritizing keywords from the best group
    _CommandTemplate? bestMatch;
    String? matchedKeyword;

    for (final entry in _commandTemplates.entries) {
      if (normalizedInput.contains(entry.key)) {
        // Calculate effective confidence
        var effectiveConfidence = entry.value.confidence;

        // Boost confidence if this keyword belongs to the best group
        if (bestGroup != null &&
            _keywordGroups[bestGroup]!.contains(entry.key)) {
          // Boost based on how many group keywords matched
          effectiveConfidence += bestGroupScore * 0.05;
        }

        // Prefer longer/more specific keywords when confidence is similar
        if (bestMatch == null ||
            effectiveConfidence > bestMatch.confidence ||
            (effectiveConfidence == bestMatch.confidence &&
                entry.key.length > (matchedKeyword?.length ?? 0))) {
          bestMatch = entry.value;
          matchedKeyword = entry.key;
        }
      }
    }

    // If we found a match, customize the command based on input
    if (bestMatch != null && matchedKeyword != null) {
      return AiSuggestion(
        command: _customizeCommand(bestMatch.command, normalizedInput),
        explanation: bestMatch.explanation,
        confidence: bestMatch.confidence,
      );
    }

    // Default fallback suggestion
    return const AiSuggestion(
      command: 'echo "Please be more specific"',
      explanation:
          'I couldn\'t understand the request. Try using keywords like "list", "find", "docker", or "pods".',
      confidence: 0.30,
    );
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(String prompt) async* {
    // Get the full suggestion first
    final suggestion = await generateCommand(prompt);

    // Simulate streaming by yielding characters one at a time
    final command = suggestion.command;
    for (var i = 0; i < command.length; i++) {
      yield AiStreamToken(command[i]);
      // Small delay between characters for streaming effect
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    // Yield the complete suggestion
    yield AiStreamComplete(suggestion);
  }

  /// Customizes command based on specific input patterns.
  String _customizeCommand(String baseCommand, String input) {
    // Add common customizations based on input
    if (input.contains('all') && baseCommand.contains('kubectl get')) {
      return '${baseCommand.replaceFirst('kubectl get', 'kubectl get')} --all-namespaces';
    }

    if (input.contains('production') && baseCommand.contains('kubectl')) {
      return '$baseCommand -n production';
    }

    if (input.contains('staging') && baseCommand.contains('kubectl')) {
      return '$baseCommand -n staging';
    }

    if (input.contains('large') && baseCommand.contains('find')) {
      return 'find . -size +100M';
    }

    if (input.contains('today') && baseCommand.contains('find')) {
      return 'find . -mtime 0';
    }

    if (input.contains('log') && baseCommand.contains('find')) {
      return 'find /var/log -name "*.log"';
    }

    return baseCommand;
  }
}

/// Internal template for command suggestions.
class _CommandTemplate {
  const _CommandTemplate({
    required this.command,
    required this.explanation,
    required this.confidence,
  });

  final String command;
  final String explanation;
  final double confidence;
}
