import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/minmoe_firmware_package.dart';
import 'package:mybiometric/services/hikvision_minmoe_ota_service.dart';

void main() {
  group('HikvisionMinMoeOtaService Suite', () {
    final pkg = MinMoeFirmwarePackage(
      packageId: 'ota_hik_01',
      modelName: 'DS-K1T671M',
      firmwareVersion: 'V3.2.30_build231015',
      fileSizeBytes: 45000000,
      sha256Checksum: 'SHA256_FIRMWARE_CHECKSUM_VALIDATION_STRING',
      downloadUrl: 'http://fw.server.corp/minmoe_v3230.dav',
      releaseDate: DateTime.parse('2026-10-01T00:00:00Z'),
    );

    test('Synthesizes valid ISAPI XML updateFirmware trigger payload', () {
      final xml = HikvisionMinMoeOtaService.instance.buildUpgradeTriggerXml(pkg);

      expect(xml.contains('<UpgradeFirmware version="2.0"'), isTrue);
      expect(xml.contains('<url>http://fw.server.corp/minmoe_v3230.dav</url>'), isTrue);
      expect(xml.contains('<sha256>SHA256_FIRMWARE_CHECKSUM_VALIDATION_STRING</sha256>'), isTrue);
    });

    test('Parses upgradeStatus XML and extracts progress percentage and status', () {
      const xml = '''<UpgradeStatus>
  <percent>65</percent>
  <status>upgrading</status>
</UpgradeStatus>''';

      final progress = HikvisionMinMoeOtaService.instance.parseUpgradeStatusXml(
        terminalId: 'term_front_01',
        packageId: 'ota_hik_01',
        xmlBody: xml,
      );

      expect(progress.percentComplete, equals(65));
      expect(progress.status, equals(MinMoeOtaStatus.flashing));
    });
  });
}
