import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// 生物识别服务 — Face ID / Fingerprint / Passcode fallback
class BiometricService {
  static final _auth = LocalAuthentication();

  /// 验证用户身份（高风险审批时调用）
  /// 返回 true = 验证成功，false = 失败/取消
  static Future<bool> authenticate({
    String reason = '验证身份以允许高风险操作',
  }) async {
    try {
      // 检查是否支持生物识别
      final available = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!available && !isDeviceSupported) {
        // Simulator 或无生物识别设备 — 直接通过
        debugPrint('[Biometric] Not available, skipping');
        return true;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // 允许 passcode 回退
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('[Biometric] Error: $e');
      return false;
    }
  }
}
