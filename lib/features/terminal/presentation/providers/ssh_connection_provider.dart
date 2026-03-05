// @telos L1:function:lib/features/terminal/presentation/providers:ssh_connection_provider

import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/ssh_datasource.dart';
import '../../domain/entities/ssh_connection_config.dart';
import '../../domain/entities/ssh_connection_state.dart';

part 'ssh_connection_provider.g.dart';

/// Notifier that manages SSH connection state.
///
/// Provides methods to connect, disconnect, and monitor connection status.
/// Exposes the underlying [SSHDataSource] for terminal I/O operations.
///
/// Uses keepAlive: true to prevent auto-disposal during navigation,
/// which would close the SSH connection unexpectedly.
@Riverpod(keepAlive: true)
class SSHConnectionNotifier extends _$SSHConnectionNotifier {
  SSHDataSource? _dataSource;
  StreamSubscription<SSHConnectionStatus>? _statusSubscription;

  @override
  SSHConnectionStatus build() {
    // Clean up on dispose
    ref.onDispose(() {
      _statusSubscription?.cancel();
      _dataSource?.close();
    });

    return const SSHConnectionStatus.disconnected();
  }

  /// Returns the data source for terminal I/O, or null if not connected.
  SSHDataSource? get dataSource => _dataSource;

  /// Establishes an SSH connection with the given configuration.
  ///
  /// Returns [Right] on success, [Left] with [Failure] on error.
  /// Updates state throughout the connection process.
  Future<Either<Failure, void>> connect(SSHConnectionConfig config) async {
    // Clean up any existing connection
    await disconnect();

    // Create new data source
    _dataSource = SSHDataSource();

    // Listen to status changes
    _statusSubscription = _dataSource!.statusStream.listen((status) {
      state = status;
    });

    // Attempt connection
    final result = await _dataSource!.connect(config);

    // If connection failed, clean up
    if (result.isLeft()) {
      await _cleanup();
    }

    return result;
  }

  /// Disconnects from the current SSH session.
  Future<void> disconnect() async {
    await _cleanup();
    state = const SSHConnectionStatus.disconnected();
  }

  /// Cleans up resources without updating state.
  Future<void> _cleanup() async {
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _dataSource?.close();
    _dataSource = null;
  }
}

/// Provider for accessing the SSH data source directly.
///
/// Returns null if not connected. Use [sSHConnectionNotifierProvider]
/// to manage the connection lifecycle.
@riverpod
SSHDataSource? sshDataSource(SshDataSourceRef ref) {
  final notifier = ref.watch(sSHConnectionNotifierProvider.notifier);
  return notifier.dataSource;
}

/// Stream provider for connection status updates.
@riverpod
Stream<SSHConnectionStatus> sshConnectionStatusStream(
  SshConnectionStatusStreamRef ref,
) async* {
  final notifier = ref.watch(sSHConnectionNotifierProvider.notifier);
  final dataSource = notifier.dataSource;

  if (dataSource != null) {
    yield* dataSource.statusStream;
  } else {
    yield const SSHConnectionStatus.disconnected();
  }
}
