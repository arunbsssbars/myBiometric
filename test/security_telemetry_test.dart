import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/security_telemetry_incident.dart';
import 'package:mybiometric/services/security_telemetry_service.dart';

void main() {
  group('SecurityTelemetryService Suite', () {
    const enterpriseId = 'ent_secure_hq';
    const userId = 'usr_field_agent';

    test('Detects impossible velocity and raises critical incident', () {
      final t1 = DateTime.parse('2026-10-05T09:00:00Z');
      final t2 = DateTime.parse('2026-10-05T09:10:00Z'); // 10 minutes later

      // Location 1: New York (40.7128, -74.0060)
      // Location 2: London (51.5074, -0.1278) - thousands of km away in 10 mins
      final incident = SecurityTelemetryService.instance.detectImpossibleTravel(
        enterpriseId: enterpriseId,
        userId: userId,
        lastLat: 40.7128,
        lastLng: -74.0060,
        lastTimestamp: t1,
        newLat: 51.5074,
        newLng: -0.1278,
        newTimestamp: t2,
      );

      expect(incident, isNotNull);
      expect(incident!.severity, equals(IncidentSeverity.critical));
      expect(incident.incidentType, equals('GEOFENCE_TELEPORT'));
      expect(incident.isActionRequired, isTrue);
    });

    test('Permits realistic local travel without raising incident', () {
      final t1 = DateTime.parse('2026-10-05T09:00:00Z');
      final t2 = DateTime.parse('2026-10-05T09:20:00Z');

      // Moving 2 km across 20 minutes (walking/traffic)
      final incident = SecurityTelemetryService.instance.detectImpossibleTravel(
        enterpriseId: enterpriseId,
        userId: userId,
        lastLat: 12.9716,
        lastLng: 77.5946,
        lastTimestamp: t1,
        newLat: 12.9720,
        newLng: 77.5950,
        newTimestamp: t2,
      );

      expect(incident, isNull);
    });

    test('Formats enterprise SIEM compliant payload', () {
      final incident = SecurityTelemetryIncident(
        incidentId: 'inc_test_01',
        enterpriseId: enterpriseId,
        userId: userId,
        incidentType: 'SPOOF_INJECTION',
        severity: IncidentSeverity.high,
        status: IncidentStatus.open,
        description: 'Liveness injection bypass attempted',
        detectedAt: DateTime.parse('2026-10-05T09:30:00Z'),
      );

      final payload = SecurityTelemetryService.instance.formatSiemPayload(incident);

      expect(payload['event_type'], equals('enterprise.attendance.security_alert'));
      expect(payload['severity'], equals('HIGH'));
      expect(payload['details']['incident_id'], equals('inc_test_01'));
      expect(payload['details']['category'], equals('SPOOF_INJECTION'));
    });
  });
}
