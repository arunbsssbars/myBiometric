import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/registered_device.dart';
import 'package:mybiometric/services/device_binding_service.dart';

void main() {
  group('DeviceBindingService & RegisteredDevice Suite', () {
    const enterpriseId = 'ent_corp_01';
    const hardwareId = 'HW_SN_889922';

    test('Fingerprint generation is deterministic', () {
      final fp1 = DeviceBindingService.computeDeviceFingerprint(
        hardwareId: hardwareId,
        brand: 'Samsung',
        model: 'Galaxy S24',
        enterpriseId: enterpriseId,
      );
      final fp2 = DeviceBindingService.computeDeviceFingerprint(
        hardwareId: hardwareId,
        brand: 'Samsung',
        model: 'Galaxy S24',
        enterpriseId: enterpriseId,
      );
      expect(fp1, equals(fp2));
      expect(fp1.length, equals(64)); // SHA-256 hex length
    });

    test('Device validation permits only trusted unrooted devices with matching fingerprint', () {
      final fp = DeviceBindingService.computeDeviceFingerprint(
        hardwareId: hardwareId,
        brand: 'Apple',
        model: 'iPhone 15',
        enterpriseId: enterpriseId,
      );

      final device = RegisteredDevice(
        deviceId: 'dev_01',
        userId: 'usr_100',
        enterpriseId: enterpriseId,
        deviceName: 'Work Phone',
        model: 'iPhone 15',
        platform: DevicePlatformType.ios,
        osVersion: '17.4',
        appVersion: '2.1.0',
        status: DeviceTrustStatus.trusted,
        deviceFingerprintSha256: fp,
        enrolledAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        isJailbrokenOrRooted: false,
      );

      // Valid match
      final isValid = DeviceBindingService.instance.validateDeviceForPunch(
        device: device,
        currentFingerprint: fp,
      );
      expect(isValid, isTrue);

      // Mismatched fingerprint
      final isTampered = DeviceBindingService.instance.validateDeviceForPunch(
        device: device,
        currentFingerprint: 'tampered_hash_string',
      );
      expect(isTampered, isFalse);

      // Rooted device
      final rootedDevice = device.copyWith(isJailbrokenOrRooted: true);
      final isRootBlocked = DeviceBindingService.instance.validateDeviceForPunch(
        device: rootedDevice,
        currentFingerprint: fp,
      );
      expect(isRootBlocked, isFalse);
    });

    test('Enforces maximum bound device limit per employee', () {
      final d1 = RegisteredDevice(
        deviceId: 'd1',
        userId: 'usr_1',
        enterpriseId: enterpriseId,
        deviceName: 'Device 1',
        model: 'Pixel 8',
        platform: DevicePlatformType.android,
        osVersion: '14',
        appVersion: '1.0',
        status: DeviceTrustStatus.trusted,
        deviceFingerprintSha256: 'hash1',
        enrolledAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      final d2 = d1.copyWith(deviceId: 'd2');

      expect(DeviceBindingService.instance.canEnrollNewDevice(existingDevices: [d1], maxAllowed: 2), isTrue);
      expect(DeviceBindingService.instance.canEnrollNewDevice(existingDevices: [d1, d2], maxAllowed: 2), isFalse);
    });

    test('Quarantine transition updates status', () {
      final device = RegisteredDevice(
        deviceId: 'dev_suspect',
        userId: 'usr_1',
        enterpriseId: enterpriseId,
        deviceName: 'Suspect Device',
        model: 'Pixel 7',
        platform: DevicePlatformType.android,
        osVersion: '14',
        appVersion: '1.0',
        status: DeviceTrustStatus.trusted,
        deviceFingerprintSha256: 'hash_s',
        enrolledAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      final quarantined = DeviceBindingService.instance.quarantineDevice(
        device: device,
        reason: 'Detected hook injection or emulator',
      );
      expect(quarantined.status, equals(DeviceTrustStatus.quarantined));
      expect(quarantined.isAllowedToPunch, isFalse);
    });
  });
}
