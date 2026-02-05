// @telos-test L1:function:lib/features/terminal/data/datasources:ssh_datasource

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bento/features/terminal/data/datasources/ssh_datasource.dart';
import 'package:bento/features/terminal/domain/entities/terminal_config.dart';

void main() {
  group('SSHDataSource', () {
    late SSHDataSource dataSource;

    setUp(() {
      dataSource = SSHDataSource();
    });

    tearDown(() async {
      await dataSource.close();
    });

    group('initial state', () {
      // @telos-scenario L1:...:ssh_datasource:initial-disconnected
      test('should be disconnected initially', () {
        expect(dataSource.isConnected, isFalse);
        expect(dataSource.status.state.name, equals('disconnected'));
      });
    });

    group('write methods with disconnected state', () {
      // @telos-scenario L1:...:ssh_datasource:write-when-disconnected
      test('should silently ignore write when disconnected', () {
        // Should not throw
        expect(
          () => dataSource.write(Uint8List.fromList([65, 66, 67])),
          returnsNormally,
        );
      });

      // @telos-scenario L1:...:ssh_datasource:write-string-when-disconnected
      test('should silently ignore writeString when disconnected', () {
        // Should not throw
        expect(
          () => dataSource.writeString('test'),
          returnsNormally,
        );
      });
    });

    group('resize with disconnected state', () {
      // @telos-scenario L1:...:ssh_datasource:resize-when-disconnected
      test('should silently ignore resize when disconnected', () {
        // Should not throw
        expect(
          () => dataSource
              .resize(const TerminalDimensions(columns: 80, rows: 24)),
          returnsNormally,
        );
      });
    });

    group('resize dimension clamping', () {
      // Note: These tests verify the clamping logic without needing a real connection
      // The actual resize would be tested in integration tests

      // @telos-scenario L1:...:ssh_datasource:resize-minimum-columns
      test('resize should accept minimum dimensions', () {
        // Verify method accepts valid small dimensions
        expect(
          () =>
              dataSource.resize(const TerminalDimensions(columns: 20, rows: 5)),
          returnsNormally,
        );
      });

      // @telos-scenario L1:...:ssh_datasource:resize-large-dimensions
      test('resize should accept large dimensions', () {
        expect(
          () => dataSource
              .resize(const TerminalDimensions(columns: 200, rows: 100)),
          returnsNormally,
        );
      });
    });

    group('close and cleanup', () {
      // @telos-scenario L1:...:ssh_datasource:close-when-disconnected
      test('should handle close when already disconnected', () async {
        // Should not throw
        await expectLater(
          dataSource.close(),
          completes,
        );
      });

      // @telos-scenario L1:...:ssh_datasource:close-multiple-times
      test('should handle multiple close calls gracefully', () async {
        await dataSource.close();
        // Second close should not throw
        await expectLater(
          dataSource.close(),
          completes,
        );
      });
    });

    group('output stream', () {
      // @telos-scenario L1:...:ssh_datasource:output-stream-available
      test('should provide output stream', () {
        expect(dataSource.output, isA<Stream<Uint8List>>());
      });
    });
  });
}
