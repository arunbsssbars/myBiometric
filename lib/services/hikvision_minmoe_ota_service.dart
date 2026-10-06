import '../domain/models/minmoe_firmware_package.dart';

/// Service managing Hikvision MinMoe ISAPI firmware upgrade triggers and status inspection
class HikvisionMinMoeOtaService {
  HikvisionMinMoeOtaService._internal();
  static final HikvisionMinMoeOtaService instance = HikvisionMinMoeOtaService._internal();

  /// Builds ISAPI XML upgrade trigger payload for PUT /ISAPI/System/updateFirmware
  String buildUpgradeTriggerXml(MinMoeFirmwarePackage package) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<UpgradeFirmware version="2.0" xmlns="http://www.isapi.org/ver20/XMLSchema">
  <url>${package.downloadUrl}</url>
  <sha256>${package.sha256Checksum}</sha256>
</UpgradeFirmware>''';
  }

  /// Parses status XML returned by GET /ISAPI/System/upgradeStatus
  MinMoeOtaProgress parseUpgradeStatusXml({
    required String terminalId,
    required String packageId,
    required String xmlBody,
  }) {
    int percent = 0;
    MinMoeOtaStatus status = MinMoeOtaStatus.downloading;

    if (xmlBody.contains('<percent>')) {
      final start = xmlBody.indexOf('<percent>') + 9;
      final end = xmlBody.indexOf('</percent>');
      if (start > 8 && end > start) {
        percent = int.tryParse(xmlBody.substring(start, end).trim()) ?? 0;
      }
    }

    if (xmlBody.contains('upgrading') || xmlBody.contains('flashing')) {
      status = MinMoeOtaStatus.flashing;
    } else if (xmlBody.contains('rebooting')) {
      status = MinMoeOtaStatus.rebooting;
    } else if (percent >= 100 || xmlBody.contains('success')) {
      status = MinMoeOtaStatus.completed;
      percent = 100;
    } else if (xmlBody.contains('failed') || xmlBody.contains('error')) {
      status = MinMoeOtaStatus.failed;
    }

    return MinMoeOtaProgress(
      terminalId: terminalId,
      packageId: packageId,
      status: status,
      percentComplete: percent,
      startedAt: DateTime.now(),
    );
  }
}
