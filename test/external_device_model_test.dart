import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/external_biometric_device.dart';

void main() {
  group('External Biometric Device Domain Model Suite', () {
    test('BiometricTerminalDevice serializes and deserializes accurately with default states', () {
      final now = DateTime(2026, 10, 1, 12, 0);
      final device = BiometricTerminalDevice(
        id: 'term-001',
        enterpriseId: 'ent-1',
        name: 'Main Lobby MinMoe Terminal',
        serialNumber: 'DS-K1T343-2026-X89',
        modelName: 'DS-K1T343EFWX',
        protocol: TerminalProtocol.hikvisionIsapi,
        ipAddress: '192.168.1.150',
        port: 80,
        username: 'admin',
        password: 'SecurePassword123!',
        branchId: 'branch-hq',
        branchName: 'Headquarters',
        status: DeviceConnectionStatus.online,
        lastHeartbeatAt: now,
        lastSyncAt: now,
        totalEventsSynced: 1420,
        autoSyncEnabled: true,
        syncIntervalMinutes: 10,
        createdAt: now,
      );

      expect(device.protocolDisplayName, 'Hikvision ISAPI');
      expect(device.isOnline, isTrue);

      final map = device.toMap();
      expect(map['modelName'], 'DS-K1T343EFWX');
      expect(map['protocol'], 'hikvisionIsapi');
      expect(map['ipAddress'], '192.168.1.150');
      expect(map['totalEventsSynced'], 1420);

      final reconstructed = BiometricTerminalDevice.fromMap(map);
      expect(reconstructed.id, device.id);
      expect(reconstructed.name, device.name);
      expect(reconstructed.protocol, TerminalProtocol.hikvisionIsapi);
      expect(reconstructed.status, DeviceConnectionStatus.online);
      expect(reconstructed.totalEventsSynced, 1420);
    });

    test('TerminalAttendanceEvent serializes and defaults correctly', () {
      final now = DateTime(2026, 10, 1, 9, 32);
      final eventWithTime = TerminalAttendanceEvent(
        eventId: 'evt-991',
        deviceId: 'term-001',
        employeeId: 'EMP-001',
        employeeName: 'Arun',
        timestamp: now,
        punchType: 'PUNCH_IN',
        authMode: DeviceAuthMode.face,
        similarityScore: 98.5,
      );

      final map = eventWithTime.toMap();
      expect(map['employeeId'], 'EMP-001');
      expect(map['punchType'], 'PUNCH_IN');
      expect(map['authMode'], 'face');
      expect(map['similarityScore'], 98.5);

      final reconstructed = TerminalAttendanceEvent.fromMap(map);
      expect(reconstructed.employeeId, 'EMP-001');
      expect(reconstructed.employeeName, 'Arun');
      expect(reconstructed.authMode, DeviceAuthMode.face);
      expect(reconstructed.similarityScore, 98.5);
    });
  });
}
