import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/device_kiosk_security_policy.dart';

/// Service managing hardware lock-down controls, escape key validation, and kiosk supervision
class DeviceKioskSecurityService {
  DeviceKioskSecurityService._internal();
  static final DeviceKioskSecurityService instance = DeviceKioskSecurityService._internal();

  /// Validates whether an entered administrator gesture or PIN matches the escape sequence hash
  bool verifyEscapeSequence({
    required DeviceKioskSecurityPolicy policy,
    required String enteredSequence,
  }) {
    final hashed = sha256.convert(utf8.encode(enteredSequence)).toString();
    return hashed == policy.adminEscapeSequenceSha256;
  }

  /// Calculates lockdown enforcement score (0 to 100)
  int calculateLockdownScore(DeviceKioskSecurityPolicy policy) {
    int score = 0;
    if (policy.disableStatusBar) score += 20;
    if (policy.disableHomeButton) score += 20;
    if (policy.disablePowerMenu) score += 20;
    if (policy.disableAppSwitching) score += 20;
    if (policy.autoRelaunchOnCrash) score += 10;
    if (policy.enableUsbAccessoryBlacklist) score += 10;
    return score;
  }
}
