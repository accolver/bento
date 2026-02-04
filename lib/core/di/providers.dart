// @telos L1:function:lib/core/di:providers

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Provides a configured Dio HTTP client.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(
        milliseconds: NetworkConstants.connectionTimeout,
      ),
      receiveTimeout: const Duration(
        milliseconds: NetworkConstants.receiveTimeout,
      ),
      sendTimeout: const Duration(milliseconds: NetworkConstants.sendTimeout),
    ),
  );

  // Add interceptors for logging, auth, etc.
  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: true, error: true),
  );

  return dio;
});

/// Provides the connectivity checker.
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Stream of connectivity changes.
final connectivityStreamProvider = StreamProvider<ConnectivityResult>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.onConnectivityChanged;
});

/// Current connectivity status.
final isConnectedProvider = FutureProvider<bool>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  final result = await connectivity.checkConnectivity();
  return result != ConnectivityResult.none;
});
