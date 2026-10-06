import 'package:flutter/foundation.dart';

enum MinMoeEnrollmentMode {
  remoteSnapshotCapture,
  cardReaderAndPhotoUpload,
  precomputedVectorImport,
}

/// Metadata and status payload for pushing employee face models to Hikvision MinMoe terminals
@immutable
class MinMoeFaceEnrollmentPayload {
  final String employeeNo;
  final String employeeName;
  final String cardNo;
  final MinMoeEnrollmentMode mode;
  final String faceDataJpegBase64;
  final String? faceLibType; // 'blackFD' or 'staticFD'
  final int validFromEpochSeconds;
  final int validToEpochSeconds;
  final bool enableDualAuthentication;

  const MinMoeFaceEnrollmentPayload({
    required this.employeeNo,
    required this.employeeName,
    required this.cardNo,
    this.mode = MinMoeEnrollmentMode.remoteSnapshotCapture,
    required this.faceDataJpegBase64,
    this.faceLibType = 'blackFD',
    required this.validFromEpochSeconds,
    required this.validToEpochSeconds,
    this.enableDualAuthentication = false,
  });

  Map<String, dynamic> toMap() => {
        'employeeNo': employeeNo,
        'employeeName': employeeName,
        'cardNo': cardNo,
        'mode': mode.name,
        'faceDataJpegBase64': faceDataJpegBase64,
        'faceLibType': faceLibType,
        'validFromEpochSeconds': validFromEpochSeconds,
        'validToEpochSeconds': validToEpochSeconds,
        'enableDualAuthentication': enableDualAuthentication,
      };

  factory MinMoeFaceEnrollmentPayload.fromMap(Map<String, dynamic> map) =>
      MinMoeFaceEnrollmentPayload(
        employeeNo: map['employeeNo'] as String? ?? '',
        employeeName: map['employeeName'] as String? ?? '',
        cardNo: map['cardNo'] as String? ?? '',
        mode: MinMoeEnrollmentMode.values.firstWhere(
          (e) => e.name == map['mode'],
          orElse: () => MinMoeEnrollmentMode.remoteSnapshotCapture,
        ),
        faceDataJpegBase64: map['faceDataJpegBase64'] as String? ?? '',
        faceLibType: map['faceLibType'] as String? ?? 'blackFD',
        validFromEpochSeconds: (map['validFromEpochSeconds'] as num?)?.toInt() ?? 0,
        validToEpochSeconds: (map['validToEpochSeconds'] as num?)?.toInt() ?? 0,
        enableDualAuthentication: map['enableDualAuthentication'] as bool? ?? false,
      );
}
