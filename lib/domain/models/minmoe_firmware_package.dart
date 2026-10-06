import 'package:flutter/foundation.dart';

enum MinMoeOtaStatus {
  idle,
  downloading,
  flashing,
  rebooting,
  completed,
  failed,
}

/// Firmware package descriptor and OTA flashing parameters for Hikvision MinMoe
@immutable
class MinMoeFirmwarePackage {
  final String packageId;
  final String modelName; // e.g. 'DS-K1T671M'
  final String firmwareVersion; // e.g. 'V3.2.30_build231015'
  final int fileSizeBytes;
  final String sha256Checksum;
  final String downloadUrl;
  final bool requiresFactoryReset;
  final DateTime releaseDate;

  const MinMoeFirmwarePackage({
    required this.packageId,
    required this.modelName,
    required this.firmwareVersion,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    required this.downloadUrl,
    this.requiresFactoryReset = false,
    required this.releaseDate,
  });

  Map<String, dynamic> toMap() => {
        'packageId': packageId,
        'modelName': modelName,
        'firmwareVersion': firmwareVersion,
        'fileSizeBytes': fileSizeBytes,
        'sha256Checksum': sha256Checksum,
        'downloadUrl': downloadUrl,
        'requiresFactoryReset': requiresFactoryReset,
        'releaseDate': releaseDate.toIso8601String(),
      };

  factory MinMoeFirmwarePackage.fromMap(Map<String, dynamic> map) =>
      MinMoeFirmwarePackage(
        packageId: map['packageId'] as String? ?? '',
        modelName: map['modelName'] as String? ?? '',
        firmwareVersion: map['firmwareVersion'] as String? ?? '',
        fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
        sha256Checksum: map['sha256Checksum'] as String? ?? '',
        downloadUrl: map['downloadUrl'] as String? ?? '',
        requiresFactoryReset: map['requiresFactoryReset'] as bool? ?? false,
        releaseDate: map['releaseDate'] != null
            ? DateTime.tryParse(map['releaseDate'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Progress state of an ongoing firmware flash operation on a MinMoe terminal
@immutable
class MinMoeOtaProgress {
  final String terminalId;
  final String packageId;
  final MinMoeOtaStatus status;
  final int percentComplete;
  final String? errorMessage;
  final DateTime startedAt;

  const MinMoeOtaProgress({
    required this.terminalId,
    required this.packageId,
    required this.status,
    required this.percentComplete,
    this.errorMessage,
    required this.startedAt,
  });
}
