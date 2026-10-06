import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_biometric_device.dart';
import 'package:mybiometric_app/services/terminal_event_payload_synthesizer.dart';

void main() {
  group('Terminal Event Payload Synthesizer Suite', () {
    final sampleDevice = BiometricTerminalDevice(
      id: 'term-main-lobby',
      enterpriseId: 'ent-1',
      name: 'Main Executive Lobby MinMoe Terminal',
      serialNumber: 'DS-K1T343-EFWX-88219',
      modelName: 'Hikvision DS-K1T343EFWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.150',
      port: 80,
      branchName: 'Headquarters & R&D Center',
      status: DeviceConnectionStatus.online,
      totalEventsSynced: 100,
      createdAt: DateTime(2026, 9, 1),
    );

    test('synthesizeHardwareEvent produces authentic Hikvision MinMoe ISAPI payload', () {
      final now = DateTime(2026, 10, 1, 9, 15, 30);
      final event = TerminalEventPayloadSynthesizer.synthesizeHardwareEvent(
        device: sampleDevice,
        employeeId: 'EMP-001',
        employeeName: 'Arun Sharma',
        punchType: 'PUNCH_IN',
        authMode: DeviceAuthMode.face,
        similarityScore: 99.6,
        timestamp: now,
      );

      expect(event.deviceId, 'term-main-lobby');
      expect(event.employeeId, 'EMP-001');
      expect(event.employeeName, 'Arun Sharma');
      expect(event.punchType, 'PUNCH_IN');
      expect(event.authMode, DeviceAuthMode.face);
      expect(event.similarityScore, 99.6);

      final decoded = jsonDecode(event.rawPayload!) as Map<String, dynamic>;
      expect(decoded['major'], 5);
      expect(decoded['minor'], 75); // Hikvision minor 75 for Face
      expect(decoded['authMode'], 15); // Hikvision authMode 15 for Face
      expect(decoded['attendanceStatus'], 0); // 0 = Check In
      expect(decoded['similarity'], 99.6);
      expect(decoded['mask'], 1);
      expect(decoded['employeeNoString'], 'EMP-001');
    });

    test('generateRawMachinePayload generates accurate ZKTeco ADMS raw stream', () {
      final now = DateTime(2026, 10, 1, 18, 0, 0);
      final rawZk = TerminalEventPayloadSynthesizer.generateRawMachinePayload(
        protocol: TerminalProtocol.zkTecoAdms,
        employeeId: 'EMP-102',
        employeeName: 'Jane Doe',
        punchType: 'PUNCH_OUT',
        authMode: DeviceAuthMode.fingerprint,
        timestamp: now,
      );

      expect(rawZk, contains('USER PIN=EMP-102'));
      expect(rawZk, contains('STATUS=1')); // Check Out
      expect(rawZk, contains('VERIFY=1')); // Fingerprint
      expect(rawZk, contains('TIME=2026-10-01 18:00:00'));
    });
  });
}
