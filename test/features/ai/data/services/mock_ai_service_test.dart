// @telos-test L1:function:lib/features/ai/data/services:mock_ai_service
import 'package:bento/features/ai/data/services/mock_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockAiService', () {
    late MockAiService service;

    setUp(() {
      // Use minimal delay for fast tests
      service = MockAiService(
        minDelay: const Duration(milliseconds: 1),
        maxDelay: const Duration(milliseconds: 10),
      );
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:mock_ai_service:list-keyword
    group('keyword matching', () {
      test('matches "list" keyword and returns ls command', () async {
        final suggestion = await service.generateCommand('list all files');

        expect(suggestion.command, equals('ls -la'));
        expect(suggestion.confidence, greaterThanOrEqualTo(0.9));
        expect(
          suggestion.explanation.toLowerCase(),
          contains('files'),
        );
      });

      test('matches "find" keyword and returns find command', () async {
        // "files" also matches and has higher confidence, so use a query
        // that only matches "find"
        final suggestion = await service.generateCommand('find something');

        expect(suggestion.command, contains('find'));
        expect(suggestion.confidence, greaterThanOrEqualTo(0.8));
      });

      test('matches "disk" keyword and returns df command', () async {
        final suggestion = await service.generateCommand('show disk usage');

        expect(suggestion.command, equals('df -h'));
        expect(suggestion.confidence, greaterThanOrEqualTo(0.9));
      });

      test('matches "docker" keyword and returns docker ps', () async {
        final suggestion = await service.generateCommand('show docker status');

        expect(suggestion.command, contains('docker'));
        expect(suggestion.confidence, greaterThanOrEqualTo(0.9));
      });

      test('matches "pods" keyword and returns kubectl command', () async {
        // Use only "pods" to avoid "list" matching with higher confidence
        final suggestion = await service.generateCommand('show pods');

        expect(suggestion.command, contains('kubectl get pods'));
        expect(suggestion.confidence, greaterThanOrEqualTo(0.9));
      });

      test('matches "git" keyword and returns git status', () async {
        final suggestion = await service.generateCommand('git status');

        expect(suggestion.command, equals('git status'));
        expect(suggestion.confidence, greaterThanOrEqualTo(0.9));
      });

      test('matches "memory" keyword and returns free command', () async {
        final suggestion = await service.generateCommand('show memory usage');

        expect(suggestion.command, equals('free -h'));
        expect(suggestion.confidence, greaterThanOrEqualTo(0.9));
      });

      test('prioritizes docker when multiple keywords match', () async {
        // This is the key test case - "list docker containers" should
        // prioritize docker-related keywords over generic "list"
        final suggestion =
            await service.generateCommand('list docker containers');

        expect(suggestion.command, contains('docker'));
        expect(suggestion.confidence, greaterThanOrEqualTo(0.9));
      });

      test('handles "list all docker containers"', () async {
        final suggestion =
            await service.generateCommand('list all docker containers');

        expect(suggestion.command, contains('docker'));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:mock_ai_service:customization
    group('command customization', () {
      test('adds --all-namespaces for "all" with kubectl', () async {
        // Use "pods" and "all" - avoid "list" which has higher confidence
        final suggestion = await service.generateCommand('show all pods');

        expect(suggestion.command, contains('--all-namespaces'));
      });

      test('adds production namespace for kubectl', () async {
        final suggestion = await service.generateCommand('get production pods');

        expect(suggestion.command, contains('-n production'));
      });

      test('adds staging namespace for kubectl', () async {
        final suggestion =
            await service.generateCommand('get staging services');

        expect(suggestion.command, contains('-n staging'));
      });

      test('searches for large files when "large" mentioned', () async {
        // Use only "find" and "large" - avoid "files" which matches higher
        final suggestion = await service.generateCommand('find large items');

        expect(suggestion.command, contains('-size'));
      });

      test('searches for today files when "today" mentioned', () async {
        // Use "find" and "today" only
        final suggestion =
            await service.generateCommand('find items from today');

        expect(suggestion.command, contains('-mtime 0'));
      });

      test('searches for today files when "today" mentioned', () async {
        // Use "find" and "today" only - be explicit about searching
        final suggestion = await service.generateCommand('find modified today');

        expect(suggestion.command, contains('-mtime 0'));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:mock_ai_service:fallback
    group('fallback behavior', () {
      test('returns low confidence for unrecognized input', () async {
        final suggestion =
            await service.generateCommand('do something random xyz');

        expect(suggestion.confidence, lessThan(0.5));
        expect(
          suggestion.explanation.toLowerCase(),
          contains('couldn\'t understand'),
        );
      });

      test('returns echo command for ambiguous input', () async {
        final suggestion = await service.generateCommand('asdfghjkl');

        expect(suggestion.command, contains('echo'));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:mock_ai_service:case-insensitive
    group('case handling', () {
      test('is case insensitive', () async {
        final lowerSuggestion = await service.generateCommand('list files');
        final upperSuggestion = await service.generateCommand('LIST FILES');
        final mixedSuggestion = await service.generateCommand('List Files');

        expect(lowerSuggestion.command, equals(upperSuggestion.command));
        expect(lowerSuggestion.command, equals(mixedSuggestion.command));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:mock_ai_service:delay
    group('delay simulation', () {
      test('respects configured delay range', () async {
        final fastService = MockAiService(
          minDelay: const Duration(milliseconds: 50),
          maxDelay: const Duration(milliseconds: 100),
        );

        final stopwatch = Stopwatch()..start();
        await fastService.generateCommand('list files');
        stopwatch.stop();

        // Should take at least minDelay
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(50));
        // Should be less than maxDelay plus some margin
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    // @telos-scenario L1:function:lib/features/ai/data/services:mock_ai_service:suggestion-structure
    group('suggestion structure', () {
      test('returns valid AiSuggestion with all fields', () async {
        final suggestion = await service.generateCommand('list files');

        expect(suggestion.command, isNotEmpty);
        expect(suggestion.explanation, isNotEmpty);
        expect(suggestion.confidence, greaterThan(0));
        expect(suggestion.confidence, lessThanOrEqualTo(1));
      });

      test('confidence is between 0 and 1', () async {
        final suggestions = await Future.wait([
          service.generateCommand('list files'),
          service.generateCommand('docker'),
          service.generateCommand('random gibberish'),
        ]);

        for (final suggestion in suggestions) {
          expect(
            suggestion.confidence,
            inInclusiveRange(0.0, 1.0),
            reason: 'confidence for "${suggestion.command}" should be 0-1',
          );
        }
      });
    });
  });
}
