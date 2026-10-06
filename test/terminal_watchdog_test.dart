import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/terminal_watchdog_incident.dart';
import 'package:mybiometric/services/terminal_watchdog_service.dart';

void main() {
  group('TerminalWatchdogService & Incident Evaluation Suite', () {
    const deviceId = 'term_frontdesk_01';

    test('Identifies healthy state when metrics within thresholds', () {
      final metrics = TerminalWatchdogMetrics(
        deviceId: deviceId,
        cpuUsagePercent: 35.0,
        ramUsagePercent: 55.0,
        diskFreeMb: 2500.0,
        consecutiveCameraFailures: 0,
        ntpDriftMillis: 120,
        capturedAt: DateTime.now(),
      );

      expect(metrics.overallState, equals(DeviceHealthState.healthy));
      final incidents = TerminalWatchdogService.instance.evaluateMetricsAndHeal(metrics: metrics);
      expect(incidents.isEmpty, isTrue);
    });

    test('Triggers self-healing remediation when camera hardware faults or disk low', () {
      final faultyMetrics = TerminalWatchdogMetrics(
        deviceId: deviceId,
        cpuUsagePercent: 40.0,
        ramUsagePercent: 94.0, // High RAM
        diskFreeMb: 45.0,     // Low Disk
        consecutiveCameraFailures: 4, // Cam failure
        ntpDriftMillis: 22000, // Drift
        capturedAt: DateTime.now(),
      );

      expect(faultyMetrics.overallState, equals(DeviceHealthState.critical));

      final incidents = TerminalWatchdogService.instance.evaluateMetricsAndHeal(metrics: faultyMetrics);
      expect(incidents.length, equals(4));

      final categories = incidents.map((i) => i.category).toSet();
      expect(categories.contains('STORAGE_EXHAUSTION'), isTrue);
      expect(categories.contains('CAMERA_FAULT'), isTrue);
      expect(categories.contains('TIME_DRIFT'), isTrue);
      expect(categories.contains('MEMORY_LEAK'), isTrue);

      for (final incident in incidents) {
        expect(incident.autoRemediated, isTrue);
        expect(incident.remediationAction, isNotNull);
      }
    });

    test('Serialization and deserialization preserve incident data', () {
      final incident = TerminalWatchdogIncident(
        incidentId: 'inc_99',
        deviceId: deviceId,
        category: 'CAMERA_FAULT',
        message: 'Camera stream disconnected',
        detectedAt: DateTime.parse('2026-10-05T00:30:00Z'),
        autoRemediated: true,
        remediationAction: 'REINITIALIZE_CAMERA_CONTROLLER',
      );

      final map = incident.toMap();
      final restored = TerminalWatchdogIncident.fromMap(map);

      expect(restored.incidentId, equals(incident.incidentId));
      expect(restored.category, equals(incident.category));
      expect(restored.autoRemediated, isTrue);
      expect(restored.remediationAction, equals('REINITIALIZE_CAMERA_CONTROLLER'));
    });
  });
}
