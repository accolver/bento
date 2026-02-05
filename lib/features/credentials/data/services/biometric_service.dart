// @telos L1:function:lib/features/credentials/data/services:biometric_service

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/errors/failures.dart';

/// Result of biometric availability check.
class BiometricAvailability {
  const BiometricAvailability({
    required this.isAvailable,
    required this.isEnrolled,
    required this.availableTypes,
  });

  /// Whether the device supports biometrics.
  final bool isAvailable;

  /// Whether biometrics are enrolled.
  final bool isEnrolled;

  /// List of available biometric types.
  final List<BiometricType> availableTypes;

  /// True if biometrics can be used.
  bool get canAuthenticate => isAvailable && isEnrolled;

  /// True if Face ID is available.
  bool get hasFaceId => availableTypes.contains(BiometricType.face);

  /// True if fingerprint/Touch ID is available.
  bool get hasFingerprint => availableTypes.contains(BiometricType.fingerprint);
}

/// Service for biometric authentication using local_auth.
///
/// Provides Face ID, Touch ID, and fingerprint authentication
/// with fallback to device PIN/password.
class BiometricService {
  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Checks biometric availability on the device.
  Future<BiometricAvailability> checkAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableTypes = await _localAuth.getAvailableBiometrics();

      return BiometricAvailability(
        isAvailable: isAvailable && isDeviceSupported,
        isEnrolled: availableTypes.isNotEmpty,
        availableTypes: availableTypes,
      );
    } on PlatformException {
      return const BiometricAvailability(
        isAvailable: false,
        isEnrolled: false,
        availableTypes: [],
      );
    }
  }

  /// Authenticates user with biometrics.
  ///
  /// [reason] is displayed to the user explaining why auth is needed.
  /// Returns [Right(true)] on success, [Right(false)] on cancel,
  /// or [Left(Failure)] on error.
  Future<Either<Failure, bool>> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      final availability = await checkAvailability();

      if (!availability.canAuthenticate) {
        if (!biometricOnly) {
          // Try device credentials (PIN/password) as fallback
          final authenticated = await _localAuth.authenticate(
            localizedReason: reason,
            options: const AuthenticationOptions(
              biometricOnly: false,
              stickyAuth: true,
            ),
          );
          return Right(authenticated);
        }
        return const Left(AuthenticationFailure(
          message: 'Biometrics not available',
        ));
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );

      return Right(authenticated);
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        return const Left(AuthenticationFailure(
          message: 'Biometrics not available on this device',
        ));
      }
      if (e.code == 'PasscodeNotSet') {
        return const Left(AuthenticationFailure(
          message: 'Device passcode not set',
        ));
      }
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return const Left(AuthenticationFailure(
          message: 'Biometrics locked. Please try again later.',
        ));
      }
      return Left(AuthenticationFailure(
        message: 'Authentication failed: ${e.message}',
      ));
    }
  }

  /// Cancels any ongoing authentication.
  Future<void> cancel() async {
    await _localAuth.stopAuthentication();
  }
}
