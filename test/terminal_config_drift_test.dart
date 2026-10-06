import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/external_biometric_device.dart';
import 'package:mybiometric/domain/models/terminal_config_baseline.dart';
import 'package:mybiometric/services/terminal_config_drift_service.dart';

void main() {
  group('TerminalConfigDriftService Tests', () {
    const baseline = TerminalConfigBaseline(
      firmwareVersionRequired: 'v4.2.0',
      expectedTimezone: 'America/Los_Angeles',
      requireFaceRecognition: true,
    );

    final deviceValid = BiometricTerminalDevice(
      id: 'term_101',
      enterpriseId: 'ent_demo',
      name: 'Main Lobby Reader',
      modelName: 'DS-K1T343MWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.100',
      customConfig: {
        'firmwareVersion': 'v4.2.0',
        'supportsFace': true,
      },
      createdAt: DateTime(2026, 1, 1),
    );

    final deviceDrifted = BiometricTerminalDevice(
      id: 'term_102',
      enterpriseId: 'ent_demo',
      name: 'Back Gate Reader',
      modelName: 'FaceDepot-7B',
      protocol: TerminalProtocol.zkTecoAdms,
      ipAddress: '192.168.1.101',
      customConfig: {
        'firmwareVersion': 'v3.9.1', // Outdated
        'supportsFace': false, // Disabled
      },
      createdAt: DateTime(2026, 1, 1),
    );

    test('Passes audit when hardware adheres to baseline', () {
      final report = TerminalConfigDriftService.auditDeviceConfig(
        device: deviceValid,
        baseline: baseline,
      );

      expect(report.hasDrift, isFalse);
      expect(report.driftDiscrepancies, isEmpty);
    });

    test('Identifies discrepancies when firmware and capabilities drift', () {
      final report = TerminalConfigDriftService.auditDeviceConfig(
        device: deviceDrifted,
        baseline: baseline,
      );

      expect(report.hasDrift, isTrue);
      expect(report.driftDiscrepancies.length, equals(2));
      expect(report.driftDiscrepancies.first, contains('Firmware mismatch'));
    });
  });
}
