import 'package:flutter/foundation.dart';

enum DeviceQoEState {
  optimal,
  degraded,
  unacceptable,
}

/// Experience and latency telemetry captured during facial biometric verification
@immutable
class BiometricQoETelemetry {
  final String sessionSessionId;
  final String deviceId;
  final int cameraCaptureLatencyMs;
  final int faceDetectionLatencyMs;
  final int embeddingExtractionLatencyMs;
  final int localVectorMatchLatencyMs;
  final int totalVerificationLatencyMs;
  final double lightingLux;
  final double facePoseAngleDegrees;
  final bool userSucceeded;
  final DateTime timestamp;

  const BiometricQoETelemetry({
    required this.sessionSessionId,
    required this.deviceId,
    required this.cameraCaptureLatencyMs,
    required this.faceDetectionLatencyMs,
    required this.embeddingExtractionLatencyMs,
    required this.localVectorMatchLatencyMs,
    required this.totalVerificationLatencyMs,
    required this.lightingLux,
    required this.facePoseAngleDegrees,
    required this.userSucceeded,
    required this.timestamp,
  });

  DeviceQoEState get qoeGrade {
    if (totalVerificationLatencyMs <= 450 && userSucceeded) {
      return DeviceQoEState.optimal;
    }
    if (totalVerificationLatencyMs <= 1200) {
      return DeviceQoEState.degraded;
    }
    return DeviceQoEState.unacceptable;
  }

  Map<String, dynamic> toMap() => {
        'sessionSessionId': sessionSessionId,
        'deviceId': deviceId,
        'cameraCaptureLatencyMs': cameraCaptureLatencyMs,
        'faceDetectionLatencyMs': faceDetectionLatencyMs,
        'embeddingExtractionLatencyMs': embeddingExtractionLatencyMs,
        'localVectorMatchLatencyMs': localVectorMatchLatencyMs,
        'totalVerificationLatencyMs': totalVerificationLatencyMs,
        'lightingLux': lightingLux,
        'facePoseAngleDegrees': facePoseAngleDegrees,
        'userSucceeded': userSucceeded,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BiometricQoETelemetry.fromMap(Map<String, dynamic> map) =>
      BiometricQoETelemetry(
        sessionSessionId: map['sessionSessionId'] as String? ?? '',
        deviceId: map['deviceId'] as String? ?? '',
        cameraCaptureLatencyMs: (map['cameraCaptureLatencyMs'] as num?)?.toInt() ?? 0,
        faceDetectionLatencyMs: (map['faceDetectionLatencyMs'] as num?)?.toInt() ?? 0,
        embeddingExtractionLatencyMs: (map['embeddingExtractionLatencyMs'] as num?)?.toInt() ?? 0,
        localVectorMatchLatencyMs: (map['localVectorMatchLatencyMs'] as num?)?.toInt() ?? 0,
        totalVerificationLatencyMs: (map['totalVerificationLatencyMs'] as num?)?.toInt() ?? 0,
        lightingLux: (map['lightingLux'] as num?)?.toDouble() ?? 300.0,
        facePoseAngleDegrees: (map['facePoseAngleDegrees'] as num?)?.toDouble() ?? 0.0,
        userSucceeded: map['userSucceeded'] as bool? ?? true,
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
