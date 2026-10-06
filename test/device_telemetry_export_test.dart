import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/device_telemetry_export_bundle.dart';
import 'package:mybiometric/services/device_telemetry_export_service.dart';

void main() {
  group('DeviceTelemetryExportService Suite', () {
    test('Formats CEF compliant event payload for SIEM collectors', () {
      final cef = DeviceTelemetryExportService.instance.formatCefEvent(
        deviceId: 'term_front_01',
        eventName: 'BIOMETRIC_PUNCH_VERIFIED',
        severity: 'LOW',
        message: 'Punch verified via Face ID at entrance',
      );

      expect(cef.startsWith('CEF:0|EnterpriseBiometrics|myBiometric|1.0|'), isTrue);
      expect(cef.contains('dvc=term_front_01'), isTrue);
      expect(cef.contains('severity=LOW') || cef.contains('|LOW|'), isTrue);
    });

    test('Creates verifiable cryptographically checksummed bundle', () {
      const rawLogs = '{"log":1}\n{"log":2}\n{"log":3}';
      final bundle = DeviceTelemetryExportService.instance.createExportBundle(
        enterpriseId: 'ent_corp',
        rawContent: rawLogs,
        format: DeviceLogFormat.jsonLd,
        recordCount: 3,
        start: DateTime.now().subtract(const Duration(hours: 24)),
        end: DateTime.now(),
      );

      expect(bundle.totalRecords, equals(3));
      expect(bundle.sha256Checksum.length, equals(64));
      expect(bundle.fileSizeBytes, greaterThan(0));
      expect(bundle.format, equals(DeviceLogFormat.jsonLd));
    });
  });
}
