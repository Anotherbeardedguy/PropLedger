import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Biometric Authentication Service
/// Handles fingerprint and face recognition for app security
class BiometricService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastAuthTimeKey = 'last_auth_time';
  
  // Lock timeout: require biometric auth after 5 minutes of inactivity
  static const Duration _lockTimeout = Duration(minutes: 5);

  BiometricService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric authentication is available (enrolled)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric is enabled in app settings
  Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
    await _secureStorage.delete(key: _lastAuthTimeKey);
  }

  /// Authenticate with biometrics
  /// Returns true if authentication successful
  Future<bool> authenticate({
    String reason = 'Please authenticate to access PropLedger',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return false;
      }

      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _updateLastAuthTime();
      }

      return authenticated;
    } on PlatformException catch (e) {
      // Handle specific error codes
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return false;
      }
      rethrow;
    }
  }

  /// Check if app should be locked (timeout expired)
  Future<bool> shouldLock() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) {
      return false;
    }

    final lastAuthTimeStr = await _secureStorage.read(key: _lastAuthTimeKey);
    if (lastAuthTimeStr == null) {
      return true; // No auth time recorded, lock
    }

    final lastAuthTime = DateTime.parse(lastAuthTimeStr);
    final now = DateTime.now();
    final elapsed = now.difference(lastAuthTime);

    return elapsed > _lockTimeout;
  }

  /// Update last authentication time
  Future<void> _updateLastAuthTime() async {
    await _secureStorage.write(
      key: _lastAuthTimeKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Get biometric type display name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get list of available biometric names
  Future<String> getAvailableBiometricsDescription() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) {
      return 'No biometrics enrolled';
    }

    final names = biometrics.map((b) => getBiometricTypeName(b)).toList();
    return names.join(', ');
  }
}
