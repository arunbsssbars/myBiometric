import 'package:flutter/foundation.dart';

/// Data model representing biometric selfie face enrollment dispatched to external physical terminals
@immutable
class MobileSelfieTerminalEnrollment {
  final String enrollmentId;
  final String employeeId;
  final String enterpriseId;
  final String employeeName;
  final String base64FaceJpeg;
  final List<double> faceFeatureVector; // 128/512-d embeddings
  final bool isSyncedToHikvisionMinMoe;
  final bool isSyncedToZkTecoAdms;
  final DateTime enrolledAt;

  const MobileSelfieTerminalEnrollment({
    required this.enrollmentId,
    required this.employeeId,
    required this.enterpriseId,
    required this.employeeName,
    required this.base64FaceJpeg,
    required this.faceFeatureVector,
    this.isSyncedToHikvisionMinMoe = false,
    this.isSyncedToZkTecoAdms = false,
    required this.enrolledAt,
  });

  Map<String, dynamic> toMap() => {
        'enrollmentId': enrollmentId,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'employeeName': employeeName,
        'base64FaceJpeg': base64FaceJpeg,
        'faceFeatureVector': faceFeatureVector,
        'isSyncedToHikvisionMinMoe': isSyncedToHikvisionMinMoe,
        'isSyncedToZkTecoAdms': isSyncedToZkTecoAdms,
        'enrolledAt': enrolledAt.toIso8601String(),
      };

  factory MobileSelfieTerminalEnrollment.fromMap(Map<String, dynamic> map) =>
      MobileSelfieTerminalEnrollment(
        enrollmentId: map['enrollmentId'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        employeeName: map['employeeName'] as String? ?? '',
        base64FaceJpeg: map['base64FaceJpeg'] as String? ?? '',
        faceFeatureVector: (map['faceFeatureVector'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const [],
        isSyncedToHikvisionMinMoe: map['isSyncedToHikvisionMinMoe'] as bool? ?? false,
        isSyncedToZkTecoAdms: map['isSyncedToZkTecoAdms'] as bool? ?? false,
        enrolledAt: map['enrolledAt'] != null
            ? DateTime.tryParse(map['enrolledAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
