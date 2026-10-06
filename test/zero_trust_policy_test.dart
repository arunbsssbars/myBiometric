import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/zero_trust_access_evaluation.dart';
import 'package:mybiometric/services/zero_trust_contextual_policy_service.dart';

void main() {
  group('ZeroTrustContextualPolicyService Suite', () {
    test('Grants access when all biometric, hardware, and geofence signals align', () {
      final decision = ZeroTrustContextualPolicyService.instance.evaluateAccessRequest(
        userId: 'usr_emp_01',
        deviceId: 'term_front_01',
        tier: DeviceAccessTier.standardEmployee,
        isMtlsAuthenticated: true,
        isHardwareKeystoreBacked: true,
        isDevicePostureCompliant: true,
        isLocationWithinGeofence: true,
        isWithinScheduledShift: true,
        biometricConfidenceScore: 0.96,
      );

      expect(decision.isAccessGranted, isTrue);
      expect(decision.confidenceScore, equals(0.96));
    });

    test('Denies access when GPS geofence boundary is breached', () {
      final decision = ZeroTrustContextualPolicyService.instance.evaluateAccessRequest(
        userId: 'usr_emp_01',
        deviceId: 'term_front_01',
        tier: DeviceAccessTier.standardEmployee,
        isMtlsAuthenticated: true,
        isHardwareKeystoreBacked: true,
        isDevicePostureCompliant: true,
        isLocationWithinGeofence: false, // Out of branch
        isWithinScheduledShift: true,
        biometricConfidenceScore: 0.95,
      );

      expect(decision.isAccessGranted, isFalse);
      expect(decision.decisionReason.contains('geofence'), isTrue);
    });

    test('Denies access for restricted admin tier when mTLS is missing', () {
      final decision = ZeroTrustContextualPolicyService.instance.evaluateAccessRequest(
        userId: 'admin_sys',
        deviceId: 'untrusted_laptop',
        tier: DeviceAccessTier.restrictedAdminOnly,
        isMtlsAuthenticated: false, // Missing mTLS
        isHardwareKeystoreBacked: false,
        isDevicePostureCompliant: true,
        isLocationWithinGeofence: true,
        isWithinScheduledShift: true,
        biometricConfidenceScore: 0.98,
      );

      expect(decision.isAccessGranted, isFalse);
      expect(decision.decisionReason.contains('mTLS'), isTrue);
    });
  });
}
