import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_biometric_device.dart';
import 'package:mybiometric_app/domain/models/terminal_batch_config.dart';
import 'package:mybiometric_app/services/terminal_firmware_manager_service.dart';

void main() {
  group('Terminal Batch Configuration & Firmware OTA Manager Suite', () {
    const testConfig = TerminalBatchConfig(
      ntpServerUrl: 'time.cloudflare.com',
      ntpPort: 123,
      faceMatchThreshold: 92,
      antiSpoofingLevel: 'HIGH',
      osdBannerText: 'Acme HQ Gate',
      doorOpenDurationSeconds: 4,
    );

    final testPackage = TerminalFirmwarePackage(
      version: 'V3.2.34_build241001',
      modelFamily: 'DS-K1T343',
      binaryUrl: 'https://firmware.acme.com/hikvision/DS-K1T343_V3.2.34.dav',
      checksumSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      releaseNotes: 'Fixed low-light IR face matching and enhanced anti-spoofing accuracy.',
      publishedAt: DateTime(2026, 10, 1),
    );

    final testDevice = BiometricTerminalDevice(
      id: 'term_hq_gate',
      enterpriseId: 'ent_demo',
      name: 'Main Entrance MinMoe',
      modelName: 'DS-K1T343MWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.110',
      createdAt: DateTime(2026, 1, 1),
    );

    test('TerminalBatchConfig serializes and deserializes accurately', () {
      final json = testConfig.toJson();
      final reconstructed = TerminalBatchConfig.fromJson(json);

      expect(reconstructed.ntpServerUrl, equals('time.cloudflare.com'));
      expect(reconstructed.faceMatchThreshold, equals(92));
      expect(reconstructed.antiSpoofingLevel, equals('HIGH'));
      expect(reconstructed.doorOpenDurationSeconds, equals(4));
    });

    test('TerminalFirmwarePackage serializes and deserializes accurately', () {
      final json = testPackage.toJson();
      final reconstructed = TerminalFirmwarePackage.fromJson(json);

      expect(reconstructed.version, equals('V3.2.34_build241001'));
      expect(reconstructed.modelFamily, equals('DS-K1T343'));
      expect(reconstructed.checksumSha256, contains('e3b0c442'));
    });

    test('TerminalFirmwareManagerService applies batch config to terminal list', () async {
      final service = TerminalFirmwareManagerService();
      final result = await service.pushBatchConfig(
        enterpriseId: 'ent_demo',
        devices: [testDevice],
        config: testConfig,
      );

      expect(result.success, isTrue);
      expect(result.devicesConfigured, equals(1));
      expect(result.failures, equals(0));
    });

    test('TerminalFirmwareManagerService triggers OTA upgrade', () async {
      final service = TerminalFirmwareManagerService();
      final ok = await service.upgradeFirmware(
        enterpriseId: 'ent_demo',
        device: testDevice,
        package: testPackage,
      );

      expect(ok, isTrue);
    });
  });
}
