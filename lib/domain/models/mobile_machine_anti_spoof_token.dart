import 'package:flutter/foundation.dart';

/// Cryptographic verification token preventing buddy punching and screen replay
@immutable
class MobileMachineAntiSpoofToken {
  final String tokenId;
  final String employeeId;
  final String enterpriseId;
  final String deviceHardwareFingerprint;
  final double gyroscopeTiltDeg;
  final double accelerometerMagnitude;
  final String signedAttestationPayload;
  final DateTime capturedAt;

  const MobileMachineAntiSpoofToken({
    required this.tokenId,
    required this.employeeId,
    required this.enterpriseId,
    required this.deviceHardwareFingerprint,
    required this.gyroscopeTiltDeg,
    required this.accelerometerMagnitude,
    required this.signedAttestationPayload,
    required this.capturedAt,
  });

  bool get isMotionNatural =>
      accelerometerMagnitude >= 8.5 && accelerometerMagnitude <= 12.0;

  Map<String, dynamic> toMap() => {
        'tokenId': tokenId,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'deviceHardwareFingerprint': deviceHardwareFingerprint,
        'gyroscopeTiltDeg': gyroscopeTiltDeg,
        'accelerometerMagnitude': accelerometerMagnitude,
        'signedAttestationPayload': signedAttestationPayload,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory MobileMachineAntiSpoofToken.fromMap(Map<String, dynamic> map) =>
      MobileMachineAntiSpoofToken(
        tokenId: map['tokenId'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        deviceHardwareFingerprint: map['deviceHardwareFingerprint'] as String? ?? '',
        gyroscopeTiltDeg: (map['gyroscopeTiltDeg'] as num?)?.toDouble() ?? 0.0,
        accelerometerMagnitude: (map['accelerometerMagnitude'] as num?)?.toDouble() ?? 9.8,
        signedAttestationPayload: map['signedAttestationPayload'] as String? ?? '',
        capturedAt: map['capturedAt'] != null
            ? DateTime.tryParse(map['capturedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
