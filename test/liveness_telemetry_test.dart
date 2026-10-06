import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/liveness_telemetry_event.dart';
import 'package:mybiometric_app/services/liveness_telemetry_service.dart';

void main() {
  group('LivenessTelemetryService Tests', () {
    test('Identifies valid live human face scan', () {
      final event = LivenessTelemetryService.evaluateScan(
        eventId: 'evt_001',
        deviceId: 'term_main_gate',
        enterpriseId: 'ent_demo',
        livenessScore: 0.96,
        faceConfidence: 0.98,
      );

      expect(event.isSpoofDetected, isFalse);
      expect(event.anomalyType, isNull);
    });

    test('Flags low liveness score as spoof / photo replay', () {
      final spoofEvent = LivenessTelemetryService.evaluateScan(
        eventId: 'evt_002',
        deviceId: 'term_main_gate',
        enterpriseId: 'ent_demo',
        livenessScore: 0.32,
        faceConfidence: 0.91,
      );

      expect(spoofEvent.isSpoofDetected, isTrue);
      expect(spoofEvent.anomalyType, equals(SpoofAnomalyType.printedPhoto));
    });

    test('Calculates aggregate spoof rate percent accurately', () {
      final events = [
        LivenessTelemetryService.evaluateScan(
          eventId: '1',
          deviceId: 'd1',
          enterpriseId: 'e1',
          livenessScore: 0.95,
          faceConfidence: 0.90,
        ),
        LivenessTelemetryService.evaluateScan(
          eventId: '2',
          deviceId: 'd1',
          enterpriseId: 'e1',
          livenessScore: 0.20,
          faceConfidence: 0.90,
        ),
      ];

      final rate = LivenessTelemetryService.calculateSpoofRatePercent(events);
      expect(rate, equals(50.0));
    });
  });
}
