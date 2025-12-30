import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/biometric_service.dart';

final biometricSettingsProvider = StateNotifierProvider<BiometricSettingsNotifier, BiometricSettings>((ref) {
  return BiometricSettingsNotifier();
});

class BiometricSettings {
  final bool isEnabled;
  final bool isSupported;
  final bool isEnrolled;
  final String availableBiometrics;

  BiometricSettings({
    required this.isEnabled,
    required this.isSupported,
    required this.isEnrolled,
    required this.availableBiometrics,
  });

  BiometricSettings copyWith({
    bool? isEnabled,
    bool? isSupported,
    bool? isEnrolled,
    String? availableBiometrics,
  }) {
    return BiometricSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      isSupported: isSupported ?? this.isSupported,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
    );
  }
}

class BiometricSettingsNotifier extends StateNotifier<BiometricSettings> {
  final BiometricService _biometricService;

  BiometricSettingsNotifier({BiometricService? biometricService})
      : _biometricService = biometricService ?? BiometricService(),
        super(BiometricSettings(
          isEnabled: false,
          isSupported: false,
          isEnrolled: false,
          availableBiometrics: '',
        )) {
    _init();
  }

  Future<void> _init() async {
    await checkBiometricStatus();
  }

  Future<void> checkBiometricStatus() async {
    final isSupported = await _biometricService.isDeviceSupported();
    final isEnrolled = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final availableBiometrics = await _biometricService.getAvailableBiometricsDescription();

    state = BiometricSettings(
      isEnabled: isEnabled,
      isSupported: isSupported,
      isEnrolled: isEnrolled,
      availableBiometrics: availableBiometrics,
    );
  }

  Future<bool> toggleBiometric(bool enabled) async {
    if (!state.isSupported) {
      throw Exception('Biometric authentication is not supported on this device');
    }

    if (!state.isEnrolled) {
      throw Exception('No biometric credentials enrolled. Please set up fingerprint/face in device settings');
    }

    if (enabled) {
      // Authenticate before enabling
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to enable biometric lock',
      );

      if (!authenticated) {
        return false;
      }

      await _biometricService.enableBiometric();
    } else {
      await _biometricService.disableBiometric();
    }

    state = state.copyWith(isEnabled: enabled);
    return true;
  }
}
