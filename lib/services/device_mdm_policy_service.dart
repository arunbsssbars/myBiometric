import '../domain/models/device_mdm_policy.dart';

/// Service auditing device hardware and OS configuration against enterprise MDM policy
class DeviceMdmPolicyService {
  DeviceMdmPolicyService._internal();
  static final DeviceMdmPolicyService instance = DeviceMdmPolicyService._internal();

  /// Audits runtime device security parameters against enterprise MDM profile
  DeviceMdmAuditReport auditDevice({
    required String deviceId,
    required DeviceMdmPolicy policy,
    required bool hasScreenPin,
    required bool isStorageEncrypted,
    required bool isUsbDebuggingActive,
    required bool isDeveloperOptionsActive,
    required bool isMockLocationActive,
    required String currentOsVersion,
  }) {
    final violations = <String>[];

    if (policy.requireScreenPin && !hasScreenPin) {
      violations.add('Screen PIN / Biometric lock is disabled on device');
    }
    if (policy.requireStorageEncryption && !isStorageEncrypted) {
      violations.add('Device storage hardware encryption is disabled');
    }
    if (policy.disallowUsbDebugging && isUsbDebuggingActive) {
      violations.add('USB Debugging (ADB) is enabled');
    }
    if (policy.disallowDeveloperOptions && isDeveloperOptionsActive) {
      violations.add('Android/iOS Developer options are active');
    }
    if (policy.disallowMockLocations && isMockLocationActive) {
      violations.add('Mock GPS Location provider active in settings');
    }

    final isCompliant = violations.isEmpty;
    return DeviceMdmAuditReport(
      deviceId: deviceId,
      policyId: policy.policyId,
      status: isCompliant
          ? DeviceProfileEnforcementStatus.compliant
          : DeviceProfileEnforcementStatus.nonCompliant,
      violations: violations,
      auditedAt: DateTime.now(),
    );
  }
}
