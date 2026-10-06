import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_biometric_device.dart';
import 'package:mybiometric_app/services/terminal_event_payload_synthesizer.dart';

void main() {
  group('Terminal Attendance Injector & Hardware Bridge Suite', () {
    final sampleDevice = BiometricTerminalDevice(
      id: 'term-north-gate',
      enterpriseId: 'ent-1',
      name: 'North Entrance Turnstile MinMoe',
      serialNumber: 'DS-K1T343-EFWX-99882',
      modelName: 'Hikvision DS-K1T343EFWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.160',
      port: 80,
      branchName: 'Headquarters',
      status: DeviceConnectionStatus.online,
      totalEventsSynced: 50,
      createdAt: DateTime(2026, 9, 1),
    );

    test('synthesizes valid hardware punch with terminal identity metadata', () {
      final now = DateTime(2026, 10, 1, 9, 0, 0);
      final event = TerminalEventPayloadSynthesizer.synthesizeHardwareEvent(
        device: sampleDevice,
        employeeId: 'EMP-007',
        employeeName: 'James Bond',
        punchType: 'PUNCH_IN',
        authMode: DeviceAuthMode.face,
        similarityScore: 99.8,
        timestamp: now,
      );

      expect(event.deviceId, 'term-north-gate');
      expect(event.punchType, 'PUNCH_IN');
      expect(event.authMode, DeviceAuthMode.face);
      expect(event.similarityScore, 99.8);
      expect(event.employeeId, 'EMP-007');
    });
  });
}
