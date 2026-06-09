import 'package:local_auth/local_auth.dart';
import 'package:pulse/services/settings_service.dart';

/// Handles biometric authentication and exposes the current lock configuration.
class AppLockService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True while a biometric prompt is on screen. The lock gate uses this to
  /// avoid re-locking the app when the OS pauses us for the prompt.
  static bool authInProgress = false;

  static bool get isLockEnabled =>
      SettingsService.appLockEnabled && SettingsService.hasPin;

  static Future<bool> isBiometricAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();
      return canCheck && available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometric(String reason) async {
    authInProgress = true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    } finally {
      // Delay clearing so the resume lifecycle event doesn't trigger a re-lock.
      Future.delayed(const Duration(milliseconds: 600), () {
        authInProgress = false;
      });
    }
  }
}
