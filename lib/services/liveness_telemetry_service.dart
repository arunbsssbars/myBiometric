import '../domain/models/liveness_telemetry_event.dart';

/// Aggregation and risk scoring service for anti-spoofing telemetry
class LivenessTelemetryService {
  /// Evaluates an individual face scan attempt against security thresholds
  static LivenessTelemetryEvent evaluateScan({
    required String eventId,
    required String deviceId,
    required String enterpriseId,
    String? attemptedUserId,
    required double livenessScore,
    required double faceConfidence,
    double livenessThreshold = 0.85,
    double confidenceThreshold = 0.80,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    if (livenessScore < 0.40) {
      return LivenessTelemetryEvent(
        id: eventId,
        deviceId: deviceId,
        enterpriseId: enterpriseId,
        attemptedUserId: attemptedUserId,
        livenessScore: livenessScore,
        faceConfidence: faceConfidence,
        isSpoofDetected: true,
        anomalyType: SpoofAnomalyType.printedPhoto,
        timestamp: now,
      );
    } else if (livenessScore < livenessThreshold) {
      return LivenessTelemetryEvent(
        id: eventId,
        deviceId: deviceId,
        enterpriseId: enterpriseId,
        attemptedUserId: attemptedUserId,
        livenessScore: livenessScore,
        faceConfidence: faceConfidence,
        isSpoofDetected: true,
        anomalyType: SpoofAnomalyType.lowLivenessConfidence,
        timestamp: now,
      );
    }

    return LivenessTelemetryEvent(
      id: eventId,
      deviceId: deviceId,
      enterpriseId: enterpriseId,
      attemptedUserId: attemptedUserId,
      livenessScore: livenessScore,
      faceConfidence: faceConfidence,
      isSpoofDetected: false,
      anomalyType: null,
      timestamp: now,
    );
  }

  /// Calculates aggregate spoof attempt rate over a list of events
  static double calculateSpoofRatePercent(List<LivenessTelemetryEvent> events) {
    if (events.isEmpty) return 0.0;
    final spoofCount = events.where((e) => e.isSpoofDetected).length;
    return (spoofCount / events.length) * 100.0;
  }
}
