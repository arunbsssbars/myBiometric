import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/device_mdm_policy.dart';
import 'package:mybiometric/services/device_mdm_policy_service.dart';

void main() {
  group('DeviceMdmPolicyService Suite', () {
    const policy = DeviceMdmPolicy(
      policyId: 'pol_strict_01',
      enterpriseId: 'ent_corp',
      requireScreenPin: true,
      requireStorageEncryption: true,
      disallowUsbDebugging: true,
      disallowDeveloperOptions: true,
      disallowMockLocations: true,
    );

    test('Passes audit when all security flags are compliant', () {
      final report = DeviceMdmPolicyService.instance.auditDevice(
        deviceId: 'dev_secure',
        policy: policy,
        hasScreenPin: true,
        isStorageEncrypted: true,
        isUsbDebuggingActive: false,
        isDeveloperOptionsActive: false,
        isMockLocationActive: false,
        currentOsVersion: '14.0',
      );

      expect(report.isCompliant, isTrue);
      expect(report.status, equals(DeviceProfileEnforcementStatus.compliant));
      expect(report.violations.isEmpty, isTrue);
    });

    test('Catches security violations when mock locations or USB debugging are enabled', () {
      final report = DeviceMdmPolicyService.instance.auditDevice(
        deviceId: 'dev_insecure',
        policy: policy,
        hasScreenPin: false,
        isStorageEncrypted: true,
        isUsbDebuggingActive: true,
        isDeveloperOptionsActive: true,
        isMockLocationActive: true,
        currentOsVersion: '14.0',
      );

      expect(report.isCompliant, isFalse);
      expect(report.status, equals(DeviceProfileEnforcementStatus.nonCompliant));
      expect(report.violations.length, equals(4));
    });
  });
}
