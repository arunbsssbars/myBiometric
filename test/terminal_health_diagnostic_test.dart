import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_biometric_device.dart';
import 'package:mybiometric_app/domain/models/terminal_diagnostic_report.dart';
import 'package:mybiometric_app/services/terminal_health_diagnostic_service.dart';

void main() {
  group('Terminal Health Diagnostic Suite', () {
    final testDevice = BiometricTerminalDevice(
      id: 'dev_hq_01',
      enterpriseId: 'ent_demo',
      name: 'HQ Turnstile North',
      modelName: 'DS-K1T343MWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.120',
      port: 80,
      createdAt: DateTime(2026, 1, 1),
    );

    test('TerminalDiagnosticReport serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 2, 14, 0);
      final report = TerminalDiagnosticReport(
        deviceId: 'dev_hq_01',
        deviceName: 'HQ Turnstile North',
        ipAddress: '192.168.1.120',
        port: 80,
        protocol: TerminalProtocol.hikvisionIsapi,
        isReachable: true,
        latencyMs: 24,
        firmwareVersion: 'V3.2.32_build240815',
        serialNumber: 'DS-K1T343-982103',
        storageUsagePercent: 42.5,
        timeDriftSeconds: 1,
        healthScore: 95,
        statusSummary: 'All systems nominal.',
        checkedAt: now,
      );

      final json = report.toJson();
      final reconstructed = TerminalDiagnosticReport.fromJson(json);

      expect(reconstructed.deviceId, equals('dev_hq_01'));
      expect(reconstructed.deviceName, equals('HQ Turnstile North'));
      expect(reconstructed.isReachable, isTrue);
      expect(reconstructed.latencyMs, equals(24));
      expect(reconstructed.healthGrade, equals(TerminalHealthGrade.excellent));
      expect(reconstructed.healthGradeLabel, equals('EXCELLENT'));
    });

    test('TerminalHealthDiagnosticService probes device and calculates appropriate health score', () async {
      final service = TerminalHealthDiagnosticService();
      final report = await service.probeDevice(testDevice);

      expect(report.deviceId, equals(testDevice.id));
      expect(report.deviceName, equals(testDevice.name));
      expect(report.isReachable, isTrue);
      expect(report.latencyMs, greaterThan(0));
      expect(report.healthScore, greaterThan(70));
      expect(report.firmwareVersion, isNotNull);
    });

    test('Unreachable device generates offline report with 0 score', () async {
      final unreachableDevice = testDevice.copyWith(
        ipAddress: '203.0.113.250', // Non-local / unroutable IP
      );

      final service = TerminalHealthDiagnosticService();
      final report = await service.probeDevice(unreachableDevice);

      expect(report.isReachable, isFalse);
      expect(report.healthScore, equals(0));
      expect(report.healthGrade, equals(TerminalHealthGrade.offline));
      expect(report.healthGradeLabel, equals('OFFLINE'));
    });
  });
}
