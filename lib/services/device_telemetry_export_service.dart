import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/device_telemetry_export_bundle.dart';

/// Service synthesizing cryptographically hashed export bundles for SIEM and enterprise cold storage
class DeviceTelemetryExportService {
  DeviceTelemetryExportService._internal();
  static final DeviceTelemetryExportService instance = DeviceTelemetryExportService._internal();

  /// Generates Common Event Format (CEF) payload string for SIEM ingestion
  String formatCefEvent({
    required String deviceId,
    required String eventName,
    required String severity,
    required String message,
  }) {
    return 'CEF:0|EnterpriseBiometrics|myBiometric|1.0|$eventName|$eventName|$severity|dvc=$deviceId msg=$message';
  }

  /// Synthesizes a signed export bundle record
  DeviceTelemetryExportBundle createExportBundle({
    required String enterpriseId,
    required String rawContent,
    required DeviceLogFormat format,
    required int recordCount,
    required DateTime start,
    required DateTime end,
  }) {
    final bytes = utf8.encode(rawContent);
    final hash = sha256.convert(bytes).toString();

    return DeviceTelemetryExportBundle(
      bundleId: 'bundle_${DateTime.now().millisecondsSinceEpoch}',
      enterpriseId: enterpriseId,
      format: format,
      totalRecords: recordCount,
      fileSizeBytes: bytes.length,
      sha256Checksum: hash,
      exportedAt: DateTime.now(),
      periodStart: start,
      periodEnd: end,
    );
  }
}
