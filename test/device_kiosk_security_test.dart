import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/device_kiosk_security_policy.dart';
import 'package:mybiometric_app/services/device_kiosk_security_service.dart';

void main() {
  group('DeviceKioskSecurityService Suite', () {
    const pin = '998877';
    final pinHash = sha256.convert(utf8.encode(pin)).toString();

    final policy = DeviceKioskSecurityPolicy(
      policyId: 'kiosk_strict_01',
      enterpriseId: 'ent_corp',
      mode: DeviceKioskPolicyMode.strictKiosk,
      disableStatusBar: true,
      disableHomeButton: true,
      disablePowerMenu: true,
      disableAppSwitching: true,
      enableUsbAccessoryBlacklist: true,
      autoRelaunchOnCrash: true,
      adminEscapeSequenceSha256: pinHash,
    );

    test('Verifies admin escape gesture/PIN correctly', () {
      final isValid = DeviceKioskSecurityService.instance.verifyEscapeSequence(
        policy: policy,
        enteredSequence: '998877',
      );
      expect(isValid, isTrue);

      final isInvalid = DeviceKioskSecurityService.instance.verifyEscapeSequence(
        policy: policy,
        enteredSequence: '123456',
      );
      expect(isInvalid, isFalse);
    });

    test('Calculates lockdown security enforcement score', () {
      final score = DeviceKioskSecurityService.instance.calculateLockdownScore(policy);
      expect(score, equals(100)); // All protections active
    });
  });
}
