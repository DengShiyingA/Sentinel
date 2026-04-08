import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate({
    String reason = '验证身份以允许高风险操作',
  }) async {
    if (kIsWeb) return true;

    try {
      final available = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();

      if (!available && !supported) return true;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (e) {
      debugPrint('[Biometric] $e');
      return false;
    }
  }

  static Future<bool> get isAvailable async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }
}
