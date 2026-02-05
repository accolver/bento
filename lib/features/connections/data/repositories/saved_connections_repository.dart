// @telos L1:function:lib/features/connections/data/repositories:saved_connections_repository

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../database/database.dart';
import '../../domain/entities/saved_connection.dart';

/// Repository for managing saved SSH connections.
///
/// Handles persistence to SQLite via Drift and secure credential
/// storage via flutter_secure_storage.
class SavedConnectionsRepository {
  SavedConnectionsRepository({
    required BentoDatabase database,
    required FlutterSecureStorage secureStorage,
  })  : _database = database,
        _secureStorage = secureStorage;

  final BentoDatabase _database;
  final FlutterSecureStorage _secureStorage;

  /// Gets all saved connections, ordered by last used (most recent first).
  Future<Either<Failure, List<SavedConnection>>> getAll() async {
    try {
      final query = _database.select(_database.savedConnections)
        ..orderBy([
          (t) => OrderingTerm.desc(t.isFavorite),
          (t) => OrderingTerm.desc(t.lastUsedAt),
          (t) => OrderingTerm.asc(t.sortOrder),
        ]);

      final rows = await query.get();
      final connections = rows.map(_rowToEntity).toList();
      return Right(connections);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to load connections: $e'));
    }
  }

  /// Gets a single connection by ID.
  Future<Either<Failure, SavedConnection?>> getById(int id) async {
    try {
      final query = _database.select(_database.savedConnections)
        ..where((t) => t.id.equals(id));

      final row = await query.getSingleOrNull();
      if (row == null) return const Right(null);

      return Right(_rowToEntity(row));
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to load connection: $e'));
    }
  }

  /// Saves a new connection or updates an existing one.
  ///
  /// If [password] is provided, it will be stored securely.
  Future<Either<Failure, SavedConnection>> save({
    required String name,
    required String host,
    required int port,
    required String username,
    required String authType,
    String? password,
    String? privateKey,
    String? terminalType,
    String? color,
    String? notes,
    int? existingId,
  }) async {
    try {
      final credentialKey =
          'bento_ssh_cred_${existingId ?? DateTime.now().millisecondsSinceEpoch}';

      // Store credential securely
      if (authType == 'password' && password != null) {
        await _secureStorage.write(key: credentialKey, value: password);
      } else if (authType == 'key' && privateKey != null) {
        await _secureStorage.write(key: credentialKey, value: privateKey);
      }

      final companion = SavedConnectionsCompanion(
        id: existingId != null ? Value(existingId) : const Value.absent(),
        name: Value(name),
        host: Value(host),
        port: Value(port),
        username: Value(username),
        authType: Value(authType),
        credentialKey: Value(credentialKey),
        terminalType: Value(terminalType ?? 'xterm-256color'),
        color: Value(color),
        notes: Value(notes),
      );

      int id;
      if (existingId != null) {
        await (_database.update(_database.savedConnections)
              ..where((t) => t.id.equals(existingId)))
            .write(companion);
        id = existingId;
      } else {
        id = await _database.into(_database.savedConnections).insert(companion);
      }

      // Update the credential key with the actual ID
      if (existingId == null) {
        final finalCredentialKey = 'bento_ssh_cred_$id';

        // Move credential to final key
        final credential = await _secureStorage.read(key: credentialKey);
        if (credential != null) {
          await _secureStorage.write(
              key: finalCredentialKey, value: credential);
          await _secureStorage.delete(key: credentialKey);
        }

        await (_database.update(_database.savedConnections)
              ..where((t) => t.id.equals(id)))
            .write(SavedConnectionsCompanion(
          credentialKey: Value(finalCredentialKey),
        ));
      }

      final result = await getById(id);
      return result.fold(
        Left.new,
        (connection) => connection != null
            ? Right(connection)
            : const Left(
                DatabaseFailure(message: 'Failed to retrieve saved connection'),
              ),
      );
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to save connection: $e'));
    }
  }

  /// Deletes a connection and its stored credentials.
  Future<Either<Failure, void>> delete(int id) async {
    try {
      // Get the connection first to find the credential key
      final result = await getById(id);
      final connection = result.fold((_) => null, (c) => c);

      if (connection?.credentialKey != null) {
        await _secureStorage.delete(key: connection!.credentialKey!);
      }

      await (_database.delete(_database.savedConnections)
            ..where((t) => t.id.equals(id)))
          .go();

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to delete connection: $e'));
    }
  }

  /// Updates the last used timestamp and increments use count.
  Future<Either<Failure, void>> markUsed(int id) async {
    try {
      final query = _database.select(_database.savedConnections)
        ..where((t) => t.id.equals(id));
      final row = await query.getSingleOrNull();

      if (row != null) {
        await (_database.update(_database.savedConnections)
              ..where((t) => t.id.equals(id)))
            .write(SavedConnectionsCompanion(
          lastUsedAt: Value(DateTime.now()),
          useCount: Value(row.useCount + 1),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update connection: $e'));
    }
  }

  /// Toggles favorite status.
  Future<Either<Failure, void>> toggleFavorite(int id) async {
    try {
      final query = _database.select(_database.savedConnections)
        ..where((t) => t.id.equals(id));
      final row = await query.getSingleOrNull();

      if (row != null) {
        await (_database.update(_database.savedConnections)
              ..where((t) => t.id.equals(id)))
            .write(SavedConnectionsCompanion(
          isFavorite: Value(!row.isFavorite),
        ));
      }

      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to update favorite: $e'));
    }
  }

  /// Gets the stored credential (password or private key) for a connection.
  Future<Either<Failure, String?>> getCredential(int id) async {
    try {
      final result = await getById(id);
      return await result.fold(
        (failure) async => Left(failure),
        (connection) async {
          if (connection?.credentialKey == null) {
            return const Right(null);
          }
          final credential = await _secureStorage.read(
            key: connection!.credentialKey!,
          );
          return Right(credential);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure(message: 'Failed to get credential: $e'));
    }
  }

  SavedConnection _rowToEntity(SavedConnectionEntry row) {
    return SavedConnection(
      id: row.id,
      name: row.name,
      host: row.host,
      port: row.port,
      username: row.username,
      authType: row.authType,
      credentialKey: row.credentialKey,
      terminalType: row.terminalType,
      color: row.color,
      notes: row.notes,
      createdAt: row.createdAt,
      lastUsedAt: row.lastUsedAt,
      useCount: row.useCount,
      isFavorite: row.isFavorite,
      sortOrder: row.sortOrder,
    );
  }
}
