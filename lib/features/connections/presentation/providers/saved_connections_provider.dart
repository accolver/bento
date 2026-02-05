// @telos L1:function:lib/features/connections/presentation/providers:saved_connections_provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../database/database.dart';
import '../../data/repositories/saved_connections_repository.dart';
import '../../domain/entities/saved_connection.dart';

part 'saved_connections_provider.g.dart';

/// Provider for secure storage instance.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

/// Provider for the SavedConnectionsRepository.
final savedConnectionsRepositoryProvider =
    Provider<SavedConnectionsRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return SavedConnectionsRepository(
    database: database,
    secureStorage: secureStorage,
  );
});

/// Provider for all saved connections.
@riverpod
Future<List<SavedConnection>> savedConnections(Ref ref) async {
  final repository = ref.watch(savedConnectionsRepositoryProvider);
  final result = await repository.getAll();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (connections) => connections,
  );
}

/// Controller for saved connections operations.
@riverpod
class SavedConnectionsController extends _$SavedConnectionsController {
  @override
  FutureOr<void> build() {
    // Initial state - nothing to do
  }

  /// Saves a new connection.
  Future<SavedConnection?> saveConnection({
    required String name,
    required String host,
    required int port,
    required String username,
    required String authType,
    String? password,
    String? privateKey,
    String? notes,
  }) async {
    final repository = ref.read(savedConnectionsRepositoryProvider);
    final result = await repository.save(
      name: name,
      host: host,
      port: port,
      username: username,
      authType: authType,
      password: password,
      privateKey: privateKey,
      notes: notes,
    );

    return result.fold(
      (failure) {
        // Don't set state on error - just return null
        return null;
      },
      (connection) {
        // Invalidate the connections list to refresh
        ref.invalidate(savedConnectionsProvider);
        return connection;
      },
    );
  }

  /// Deletes a connection.
  Future<bool> deleteConnection(int id) async {
    final repository = ref.read(savedConnectionsRepositoryProvider);
    final result = await repository.delete(id);

    return result.fold(
      (failure) => false,
      (_) {
        ref.invalidate(savedConnectionsProvider);
        return true;
      },
    );
  }

  /// Marks a connection as used.
  Future<void> markUsed(int id) async {
    final repository = ref.read(savedConnectionsRepositoryProvider);
    await repository.markUsed(id);
    ref.invalidate(savedConnectionsProvider);
  }

  /// Toggles favorite status.
  Future<void> toggleFavorite(int id) async {
    final repository = ref.read(savedConnectionsRepositoryProvider);
    await repository.toggleFavorite(id);
    ref.invalidate(savedConnectionsProvider);
  }

  /// Gets the credential for a connection.
  Future<String?> getCredential(int id) async {
    final repository = ref.read(savedConnectionsRepositoryProvider);
    final result = await repository.getCredential(id);
    return result.fold(
      (failure) => null,
      (credential) => credential,
    );
  }
}
