// @telos-test L1:function:lib/features/connections/data/repositories:saved_connections_repository

import 'package:bento/database/database.dart';
import 'package:bento/features/connections/data/repositories/saved_connections_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late BentoDatabase database;
  late MockFlutterSecureStorage mockSecureStorage;
  late SavedConnectionsRepository repository;

  setUp(() {
    database = BentoDatabase.forTesting(
      NativeDatabase.memory(),
    );
    mockSecureStorage = MockFlutterSecureStorage();
    repository = SavedConnectionsRepository(
      database: database,
      secureStorage: mockSecureStorage,
    );

    // Set up common mocks for secure storage
    when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => mockSecureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => 'password123');
    when(() => mockSecureStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});
  });

  tearDown(() async {
    await database.close();
  });

  group('SavedConnectionsRepository', () {
    group('view mode preference', () {
      // @telos-scenario L1:...:saved_connections_repository:default-view-mode
      test('new connections have default view mode of split', () async {
        final result = await repository.save(
          name: 'Test Server',
          host: 'test.example.com',
          port: 22,
          username: 'testuser',
          authType: 'password',
          password: 'password123',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (connection) {
            expect(connection.preferredViewMode, 'split');
          },
        );
      });

      // @telos-scenario L1:...:saved_connections_repository:update-view-mode
      test('updateViewModePreference updates the stored preference', () async {
        // Create a connection first
        final createResult = await repository.save(
          name: 'Test Server',
          host: 'test.example.com',
          port: 22,
          username: 'testuser',
          authType: 'password',
          password: 'password123',
        );

        expect(createResult.isRight(), true);
        final connection = createResult.fold(
          (failure) => throw Exception(failure.message),
          (conn) => conn,
        );

        // Update view mode to fullTerminal
        final updateResult = await repository.updateViewModePreference(
          connection.id,
          'fullTerminal',
        );

        expect(updateResult.isRight(), true);

        // Fetch the connection again
        final fetchResult = await repository.getById(connection.id);

        expect(fetchResult.isRight(), true);
        fetchResult.fold(
          (failure) => fail('Should not fail'),
          (updated) {
            expect(updated?.preferredViewMode, 'fullTerminal');
          },
        );
      });

      // @telos-scenario L1:...:saved_connections_repository:update-view-mode-fullblocks
      test('can set view mode to fullBlocks', () async {
        // Create a connection
        final createResult = await repository.save(
          name: 'Test Server',
          host: 'test.example.com',
          port: 22,
          username: 'testuser',
          authType: 'password',
          password: 'password123',
        );

        final connection = createResult.fold(
          (failure) => throw Exception(failure.message),
          (conn) => conn,
        );

        // Update view mode to fullBlocks
        await repository.updateViewModePreference(connection.id, 'fullBlocks');

        // Verify
        final fetchResult = await repository.getById(connection.id);
        fetchResult.fold(
          (failure) => fail('Should not fail'),
          (updated) {
            expect(updated?.preferredViewMode, 'fullBlocks');
          },
        );
      });

      // @telos-scenario L1:...:saved_connections_repository:view-mode-persisted
      test('view mode preference persists across fetches', () async {
        // Create connection and set view mode
        final createResult = await repository.save(
          name: 'Test Server',
          host: 'test.example.com',
          port: 22,
          username: 'testuser',
          authType: 'password',
          password: 'password123',
        );

        final connection = createResult.fold(
          (failure) => throw Exception(failure.message),
          (conn) => conn,
        );
        await repository.updateViewModePreference(
            connection.id, 'fullTerminal');

        // Fetch via getAll
        final allResult = await repository.getAll();

        expect(allResult.isRight(), true);
        allResult.fold(
          (failure) => fail('Should not fail'),
          (connections) {
            expect(connections.length, 1);
            expect(connections.first.preferredViewMode, 'fullTerminal');
          },
        );
      });
    });
  });
}
