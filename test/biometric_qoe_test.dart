import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/biometric_qoe_telemetry.dart';
import 'package:mybiometric_app/services/biometric_qoe_analytics_service.dart';

void main() {
  group('BiometricQoEAnalyticsService Suite', () {
    test('Calculates accurate average and P95 latency metrics', () {
      final sessions = [
        BiometricQoETelemetry(
          sessionSessionId: 's1',
          deviceId: 'd1',
          cameraCaptureLatencyMs: 100,
          faceDetectionLatencyMs: 80,
          embeddingExtractionLatencyMs: 120,
          localVectorMatchLatencyMs: 20,
          totalVerificationLatencyMs: 320,
          lightingLux: 400.0,
          facePoseAngleDegrees: 2.0,
          userSucceeded: true,
          timestamp: DateTime.now(),
        ),
        BiometricQoETelemetry(
          sessionSessionId: 's2',
          deviceId: 'd1',
          cameraCaptureLatencyMs: 110,
          faceDetectionLatencyMs: 90,
          embeddingExtractionLatencyMs: 130,
          localVectorMatchLatencyMs: 25,
          totalVerificationLatencyMs: 355,
          lightingLux: 410.0,
          facePoseAngleDegrees: 3.0,
          userSucceeded: true,
          timestamp: DateTime.now(),
        ),
        BiometricQoETelemetry(
          sessionSessionId: 's3',
          deviceId: 'd1',
          cameraCaptureLatencyMs: 200,
          faceDetectionLatencyMs: 180,
          embeddingExtractionLatencyMs: 300,
          localVectorMatchLatencyMs: 40,
          totalVerificationLatencyMs: 720,
          lightingLux: 200.0,
          facePoseAngleDegrees: 15.0,
          userSucceeded: false,
          timestamp: DateTime.now(),
        ),
      ];

      final stats = BiometricQoEAnalyticsService.instance.aggregateQoEPerformance(sessions);

      expect(stats['totalSessions'], equals(3));
      expect(stats['averageLatencyMs'], equals(465));
      expect(stats['p95LatencyMs'], equals(720));
      expect(stats['successRate'], equals(66.7));
      expect(stats['degradedPercentage'], equals(33.3));
    });

    test('Classifies QoE experience state based on latency and success', () {
      final fast = BiometricQoETelemetry(
        sessionSessionId: 's_fast',
        deviceId: 'd1',
        cameraCaptureLatencyMs: 100,
        faceDetectionLatencyMs: 80,
        embeddingExtractionLatencyMs: 120,
        localVectorMatchLatencyMs: 20,
        totalVerificationLatencyMs: 320,
        lightingLux: 400.0,
        facePoseAngleDegrees: 2.0,
        userSucceeded: true,
        timestamp: DateTime.now(),
      );
      expect(fast.qoeGrade, equals(DeviceQoEState.optimal));

      final slow = BiometricQoETelemetry(
        sessionSessionId: 's_slow',
        deviceId: 'd1',
        cameraCaptureLatencyMs: 300,
        faceDetectionLatencyMs: 400,
        embeddingExtractionLatencyMs: 500,
        localVectorMatchLatencyMs: 100,
        totalVerificationLatencyMs: 1300,
        lightingLux: 100.0,
        facePoseAngleDegrees: 25.0,
        userSucceeded: true,
        timestamp: DateTime.now(),
      );
      expect(slow.qoeGrade, equals(DeviceQoEState.unacceptable));
    });
  });
}
