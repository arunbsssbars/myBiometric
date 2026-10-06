import 'package:flutter/foundation.dart';

enum DeviceAccessTier {
  standardEmployee,
  privilegedContractor,
  securityStaff,
  executiveEscort,
  restrictedAdminOnly,
}

/// Zero-trust access posture evaluated at the instant of biometric scan
@immutable
class ZeroTrustAccessEvaluation {
  final String evaluationId;
  final String userId;
  final String deviceId;
  final DeviceAccessTier accessTier;
  final bool isMtlsAuthenticated;
  final bool isHardwareKeystoreBacked;
  final bool isDevicePostureCompliant;
  final bool isLocationWithinGeofence;
  final bool isWithinScheduledShift;
  final double confidenceScore;
  final bool isAccessGranted;
  final String decisionReason;
  final DateTime evaluatedAt;

  const ZeroTrustAccessEvaluation({
    required this.evaluationId,
    required this.userId,
    required this.deviceId,
    required this.accessTier,
    required this.isMtlsAuthenticated,
    required this.isHardwareKeystoreBacked,
    required this.isDevicePostureCompliant,
    required this.isLocationWithinGeofence,
    required this.isWithinScheduledShift,
    required this.confidenceScore,
    required this.isAccessGranted,
    required this.decisionReason,
    required this.evaluatedAt,
  });

  Map<String, dynamic> toMap() => {
        'evaluationId': evaluationId,
        'userId': userId,
        'deviceId': deviceId,
        'accessTier': accessTier.name,
        'isMtlsAuthenticated': isMtlsAuthenticated,
        'isHardwareKeystoreBacked': isHardwareKeystoreBacked,
        'isDevicePostureCompliant': isDevicePostureCompliant,
        'isLocationWithinGeofence': isLocationWithinGeofence,
        'isWithinScheduledShift': isWithinScheduledShift,
        'confidenceScore': confidenceScore,
        'isAccessGranted': isAccessGranted,
        'decisionReason': decisionReason,
        'evaluatedAt': evaluatedAt.toIso8601String(),
      };

  factory ZeroTrustAccessEvaluation.fromMap(Map<String, dynamic> map) =>
      ZeroTrustAccessEvaluation(
        evaluationId: map['evaluationId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        deviceId: map['deviceId'] as String? ?? '',
        accessTier: DeviceAccessTier.values.firstWhere(
          (e) => e.name == map['accessTier'],
          orElse: () => DeviceAccessTier.standardEmployee,
        ),
        isMtlsAuthenticated: map['isMtlsAuthenticated'] as bool? ?? false,
        isHardwareKeystoreBacked: map['isHardwareKeystoreBacked'] as bool? ?? false,
        isDevicePostureCompliant: map['isDevicePostureCompliant'] as bool? ?? false,
        isLocationWithinGeofence: map['isLocationWithinGeofence'] as bool? ?? false,
        isWithinScheduledShift: map['isWithinScheduledShift'] as bool? ?? false,
        confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
        isAccessGranted: map['isAccessGranted'] as bool? ?? false,
        decisionReason: map['decisionReason'] as String? ?? '',
        evaluatedAt: map['evaluatedAt'] != null
            ? DateTime.tryParse(map['evaluatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
