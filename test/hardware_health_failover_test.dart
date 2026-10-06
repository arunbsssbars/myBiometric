import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_hardware_device.dart';
import 'package:mybiometric_app/services/hardware_health_failover_service.dart';

void main() {
  group('HardwareHealthFailoverService Unit Tests', () {
    late HardwareHealthFailoverService service;

    setUp(() {
      service = HardwareHealthFailoverService();
    });

    test('calculates 100% resilience when all devices are healthy', () {
      final dev1 = ExternalHardwareDevice(
        deviceId: 'dev-1',
        enterpriseId: 'ent-1',
        deviceName: 'North Gate Turnstile',
        ipAddress: '192.168.1.100',
        vendor: TimeclockVendor.zkteco,
        serialNumber: 'ZK-001',
        lastHeartbeat: DateTime.now(),
      );
      final dev2 = ExternalHardwareDevice(
        deviceId: 'dev-2',
        enterpriseId: 'ent-1',
        deviceName: 'South Gate Turnstile',
        ipAddress: '192.168.1.101',
        vendor: TimeclockVendor.hikvision,
        serialNumber: 'HIK-002',
        lastHeartbeat: DateTime.now(),
      );

      service.registerDevice(dev1);
      service.registerDevice(dev2);

      expect(service.calculateFleetResilience('ent-1'), 100.0);
    });

    test('resolves failover to device in same location when primary is offline', () {
      final devPrimary = ExternalHardwareDevice(
        deviceId: 'dev-1',
        enterpriseId: 'ent-1',
        deviceName: 'Lobby Primary',
        ipAddress: '192.168.1.100',
        vendor: TimeclockVendor.zkteco,
        serialNumber: 'ZK-001',
        locationTag: 'Lobby',
        status: DeviceHealthStatus.offline,
        lastHeartbeat: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final devBackup = ExternalHardwareDevice(
        deviceId: 'dev-2',
        enterpriseId: 'ent-1',
        deviceName: 'Lobby Secondary',
        ipAddress: '192.168.1.101',
        vendor: TimeclockVendor.hikvision,
        serialNumber: 'HIK-002',
        locationTag: 'Lobby',
        status: DeviceHealthStatus.online,
        lastHeartbeat: DateTime.now(),
        pendingLogsCount: 5,
      );

      service.registerDevice(devPrimary);
      service.registerDevice(devBackup);

      final failover = service.resolveFailoverDevice(
        failedDeviceId: 'dev-1',
        enterpriseId: 'ent-1',
      );

      expect(failover, isNotNull);
      expect(failover!.deviceId, 'dev-2');
      expect(failover.deviceName, 'Lobby Secondary');
    });
  });
}
