import 'package:flutter/foundation.dart';

enum DeviceProfileEnforcementStatus {
  compliant,
  nonCompliant,
  quarantined,
}

/// MDM/EMM policy configuration pushed to company-owned attendance devices
@immutable
class DeviceMdmPolicy {
  final String policyId;
  final String enterpriseId;
  final bool requireScreenPin;
  final bool requireStorageEncryption;
  final bool disallowUsbDebugging;
  final bool disallowDeveloperOptions;
  final bool disallowMockLocations;
  final bool disallowCameraScreenRecording;
  final String minimumOsVersion;
  final int maxFailedPinAttempts;

  const DeviceMdmPolicy({
    required this.policyId,
    required this.enterpriseId,
    this.requireScreenPin = true,
    this.requireStorageEncryption = true,
    this.disallowUsbDebugging = true,
    this.disallowDeveloperOptions = true,
    this.disallowMockLocations = true,
    this.disallowCameraScreenRecording = true,
    this.minimumOsVersion = '12.0',
    this.maxFailedPinAttempts = 5,
  });

  Map<String, dynamic> toMap() => {
        'policyId': policyId,
        'enterpriseId': enterpriseId,
        'requireScreenPin': requireScreenPin,
        'requireStorageEncryption': requireStorageEncryption,
        'disallowUsbDebugging': disallowUsbDebugging,
        'disallowDeveloperOptions': disallowDeveloperOptions,
        'disallowMockLocations': disallowMockLocations,
        'disallowCameraScreenRecording': disallowCameraScreenRecording,
        'minimumOsVersion': minimumOsVersion,
        'maxFailedPinAttempts': maxFailedPinAttempts,
      };

  factory DeviceMdmPolicy.fromMap(Map<String, dynamic> map) =>
      DeviceMdmPolicy(
        policyId: map['policyId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        requireScreenPin: map['requireScreenPin'] as bool? ?? true,
        requireStorageEncryption: map['requireStorageEncryption'] as bool? ?? true,
        disallowUsbDebugging: map['disallowUsbDebugging'] as bool? ?? true,
        disallowDeveloperOptions: map['disallowDeveloperOptions'] as bool? ?? true,
        disallowMockLocations: map['disallowMockLocations'] as bool? ?? true,
        disallowCameraScreenRecording: map['disallowCameraScreenRecording'] as bool? ?? true,
        minimumOsVersion: map['minimumOsVersion'] as String? ?? '12.0',
        maxFailedPinAttempts: (map['maxFailedPinAttempts'] as num?)?.toInt() ?? 5,
      );
}

/// Audit report comparing device state against enforced MDM policy
@immutable
class DeviceMdmAuditReport {
  final String deviceId;
  final String policyId;
  final DeviceProfileEnforcementStatus status;
  final List<String> violations;
  final DateTime auditedAt;

  const DeviceMdmAuditReport({
    required this.deviceId,
    required this.policyId,
    required this.status,
    required this.violations,
    required this.auditedAt,
  });

  bool get isCompliant => status == DeviceProfileEnforcementStatus.compliant;
}
