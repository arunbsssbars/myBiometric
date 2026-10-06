import 'package:flutter/foundation.dart';

enum DeviceLogFormat {
  jsonLd,
  cefCommonEventFormat,
  syslogRfc5424,
  csvTable,
}

/// Batch export of device operational and attendance telemetry for compliance and SIEM archiving
@immutable
class DeviceTelemetryExportBundle {
  final String bundleId;
  final String enterpriseId;
  final DeviceLogFormat format;
  final int totalRecords;
  final int fileSizeBytes;
  final String sha256Checksum;
  final DateTime exportedAt;
  final DateTime periodStart;
  final DateTime periodEnd;

  const DeviceTelemetryExportBundle({
    required this.bundleId,
    required this.enterpriseId,
    required this.format,
    required this.totalRecords,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    required this.exportedAt,
    required this.periodStart,
    required this.periodEnd,
  });

  Map<String, dynamic> toMap() => {
        'bundleId': bundleId,
        'enterpriseId': enterpriseId,
        'format': format.name,
        'totalRecords': totalRecords,
        'fileSizeBytes': fileSizeBytes,
        'sha256Checksum': sha256Checksum,
        'exportedAt': exportedAt.toIso8601String(),
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };

  factory DeviceTelemetryExportBundle.fromMap(Map<String, dynamic> map) =>
      DeviceTelemetryExportBundle(
        bundleId: map['bundleId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        format: DeviceLogFormat.values.firstWhere(
          (e) => e.name == map['format'],
          orElse: () => DeviceLogFormat.jsonLd,
        ),
        totalRecords: (map['totalRecords'] as num?)?.toInt() ?? 0,
        fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
        sha256Checksum: map['sha256Checksum'] as String? ?? '',
        exportedAt: map['exportedAt'] != null
            ? DateTime.tryParse(map['exportedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        periodStart: map['periodStart'] != null
            ? DateTime.tryParse(map['periodStart'] as String) ?? DateTime.now()
            : DateTime.now(),
        periodEnd: map['periodEnd'] != null
            ? DateTime.tryParse(map['periodEnd'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
