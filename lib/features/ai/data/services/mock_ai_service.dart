// @telos L1:function:lib/features/ai/data/services:mock_ai_service

import 'dart:math';

import '../../domain/entities/ai_privacy_mode.dart';
import '../../domain/entities/ai_suggestion.dart';
import '../../domain/services/ai_service.dart';

/// Mock AI service for testing and demo purposes.
///
/// Uses keyword matching to generate plausible command suggestions
/// without requiring any actual AI model or network connection.
///
/// This is used:
/// - During development/testing
/// - As a fallback when no AI provider is configured
/// - For demo/onboarding flows
class MockAiService implements AiService {
  MockAiService({
    this.minDelay = const Duration(milliseconds: 100),
    this.maxDelay = const Duration(milliseconds: 500),
  });

  /// Minimum simulated delay before returning a suggestion.
  final Duration minDelay;

  /// Maximum simulated delay before returning a suggestion.
  final Duration maxDelay;

  final _random = Random();

  /// Keyword-to-command mapping with priorities.
  /// Higher priority entries are preferred when multiple keywords match.
  static const _keywordMap = <_KeywordEntry>[
    // Docker (priority 10 - specific tool)
    _KeywordEntry(
      keywords: ['docker', 'container'],
      command: 'docker ps -a',
      explanation: 'List all Docker containers (running and stopped)',
      confidence: 0.95,
      priority: 10,
      customizations: {
        'logs': 'docker logs --tail 50 -f',
        'stop': 'docker stop \$(docker ps -q)',
        'prune': 'docker system prune -af',
      },
    ),
    // Kubernetes (priority 10)
    _KeywordEntry(
      keywords: ['pods', 'kubernetes', 'k8s', 'kubectl', 'services'],
      command: 'kubectl get pods',
      explanation: 'List Kubernetes pods in the current namespace',
      confidence: 0.95,
      priority: 10,
      customizations: {
        'all': 'kubectl get pods --all-namespaces',
        'production': 'kubectl get pods -n production',
        'staging': 'kubectl get pods -n staging',
        'services': 'kubectl get services',
      },
    ),
    // Git (priority 9)
    _KeywordEntry(
      keywords: ['git'],
      command: 'git status',
      explanation: 'Show the working tree status',
      confidence: 0.95,
      priority: 9,
      customizations: {
        'log': 'git log --oneline -10',
        'diff': 'git diff',
        'branch': 'git branch -a',
      },
    ),
    // Find (priority 5)
    _KeywordEntry(
      keywords: ['find', 'search'],
      command: 'find . -name "*.txt"',
      explanation: 'Find files matching pattern',
      confidence: 0.85,
      priority: 5,
      customizations: {
        'large': 'find . -type f -size +100M',
        'today': 'find . -type f -mtime 0',
        'empty': 'find . -type f -empty',
      },
    ),
    // Disk (priority 7)
    _KeywordEntry(
      keywords: ['disk', 'space', 'storage'],
      command: 'df -h',
      explanation: 'Show disk space usage in human-readable format',
      confidence: 0.9,
      priority: 7,
    ),
    // Memory (priority 7)
    _KeywordEntry(
      keywords: ['memory', 'ram'],
      command: 'free -h',
      explanation: 'Show memory usage in human-readable format',
      confidence: 0.9,
      priority: 7,
    ),
    // Process (priority 6)
    _KeywordEntry(
      keywords: ['process', 'cpu', 'top'],
      command: 'top -b -n 1 | head -20',
      explanation: 'Show top processes by CPU usage',
      confidence: 0.85,
      priority: 6,
    ),
    // Network (priority 6)
    _KeywordEntry(
      keywords: ['network', 'port', 'listen'],
      command: 'ss -tlnp',
      explanation: 'Show listening TCP ports',
      confidence: 0.85,
      priority: 6,
    ),
    // List files (priority 3 - generic)
    _KeywordEntry(
      keywords: ['list', 'files', 'directory', 'ls'],
      command: 'ls -la',
      explanation: 'List all files with detailed information',
      confidence: 0.9,
      priority: 3,
    ),
  ];

  @override
  String get serviceName => 'Mock AI';

  @override
  AiPrivacyMode get privacyMode => AiPrivacyMode.local;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<AiSuggestion> generateCommand(String prompt) async {
    // Simulate processing delay
    final delay = minDelay +
        Duration(
          milliseconds:
              _random.nextInt((maxDelay - minDelay).inMilliseconds.abs() + 1),
        );
    await Future.delayed(delay);

    return _matchKeywords(prompt);
  }

  @override
  Stream<AiStreamEvent> generateCommandStream(String prompt) async* {
    // Simulate processing delay
    final delay = minDelay +
        Duration(
          milliseconds:
              _random.nextInt((maxDelay - minDelay).inMilliseconds.abs() + 1),
        );
    await Future.delayed(delay);

    final suggestion = _matchKeywords(prompt);

    // Simulate streaming by yielding tokens character by character
    for (var i = 0; i < suggestion.command.length; i++) {
      yield AiStreamToken(suggestion.command[i]);
      await Future.delayed(const Duration(microseconds: 100));
    }

    yield AiStreamComplete(suggestion);
  }

  @override
  Future<String> summarizeOutput(String command, String output) async {
    // Simple mock summarization
    final lineCount = output.split('\n').length;
    return 'Command produced $lineCount lines of output.';
  }

  @override
  Future<void> dispose() async {
    // No resources to clean up
  }

  /// Match keywords in the prompt to find the best command suggestion.
  AiSuggestion _matchKeywords(String prompt) {
    final lowerPrompt = prompt.toLowerCase();
    final words = lowerPrompt.split(RegExp(r'\s+'));

    // Find all matching entries
    final matches = <_KeywordMatch>[];

    for (final entry in _keywordMap) {
      final matchedKeywords = entry.keywords
          .where((kw) => words.any((w) => w.contains(kw)))
          .toList();

      if (matchedKeywords.isNotEmpty) {
        matches.add(_KeywordMatch(
          entry: entry,
          matchCount: matchedKeywords.length,
        ));
      }
    }

    if (matches.isEmpty) {
      // No matches - return fallback
      return AiSuggestion(
        command: 'echo "$prompt"',
        explanation: "Couldn't understand the request. Echoing input.",
        confidence: 0.3,
      );
    }

    // Sort by priority (highest first), then by match count
    matches.sort((a, b) {
      final priorityCompare = b.entry.priority.compareTo(a.entry.priority);
      if (priorityCompare != 0) return priorityCompare;
      return b.matchCount.compareTo(a.matchCount);
    });

    final best = matches.first;
    var command = best.entry.command;
    var explanation = best.entry.explanation;

    // Apply customizations based on additional keywords
    if (best.entry.customizations != null) {
      for (final customEntry in best.entry.customizations!.entries) {
        if (words.any((w) => w.contains(customEntry.key))) {
          command = customEntry.value;
          break;
        }
      }
    }

    return AiSuggestion(
      command: command,
      explanation: explanation,
      confidence: best.entry.confidence,
    );
  }
}

/// A keyword entry in the matching table.
class _KeywordEntry {
  const _KeywordEntry({
    required this.keywords,
    required this.command,
    required this.explanation,
    required this.confidence,
    required this.priority,
    this.customizations,
  });

  final List<String> keywords;
  final String command;
  final String explanation;
  final double confidence;
  final int priority;
  final Map<String, String>? customizations;
}

/// A matched keyword entry with match count.
class _KeywordMatch {
  const _KeywordMatch({
    required this.entry,
    required this.matchCount,
  });

  final _KeywordEntry entry;
  final int matchCount;
}
