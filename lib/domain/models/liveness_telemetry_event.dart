import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of anti-spoofing challenge/anomaly
enum SpoofAnomalyType {
  printedPhoto,
  digitalScreenReplay,
  threeDimensionalMask,
  lowLivenessConfidence,
  rapidMultiFaceCollision,
}

/// Represents an anti-spoofing / face liveness detection telemetry event
class LivenessTelemetryEvent {
  final String id;
  final String deviceId;
  final String enterpriseId;
  final String? attemptedUserId;
  final double livenessScore; // 0.0 to 1.0 (e.g. >= 0.85 passes)
  final double faceConfidence; // 0.0 to 1.0
  final bool isSpoofDetected;
  final SpoofAnomalyType? anomalyType;
  final DateTime timestamp;

  const LivenessTelemetryEvent({
    required this.id,
    required this.deviceId,
    required this.enterpriseId,
    this.attemptedUserId,
    required this.livenessScore,
    required this.faceConfidence,
    required this.isSpoofDetected,
    this.anomalyType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'enterpriseId': enterpriseId,
      'attemptedUserId': attemptedUserId,
      'livenessScore': livenessScore,
      'faceConfidence': faceConfidence,
      'isSpoofDetected': isSpoofDetected,
      'anomalyType': anomalyType?.name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory LivenessTelemetryEvent.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return LivenessTelemetryEvent(
      id: docId ?? map['id'] ?? '',
      deviceId: map['deviceId'] ?? '',
      enterpriseId: map['enterpriseId'] ?? '',
      attemptedUserId: map['attemptedUserId'],
      livenessScore: (map['livenessScore'] as num?)?.toDouble() ?? 0.0,
      faceConfidence: (map['faceConfidence'] as num?)?.toDouble() ?? 0.0,
      isSpoofDetected: map['isSpoofDetected'] ?? false,
      anomalyType: map['anomalyType'] != null
          ? SpoofAnomalyType.values.firstWhere(
              (e) => e.name == map['anomalyType'],
              orElse: () => SpoofAnomalyType.lowLivenessConfidence,
            )
          : null,
      timestamp: parseDate(map['timestamp']),
    );
  }
}
