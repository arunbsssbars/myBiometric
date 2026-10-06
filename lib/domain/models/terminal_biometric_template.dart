import 'dart:convert';
import 'dart:typed_data';

/// Sync status of a biometric template across external physical hardware machines.
enum BiometricTemplateSyncStatus {
  synchronized,
  pendingPush,
  failed,
  unregistered,
}

/// Domain model encapsulating biometric face templates, facial landmark vectors,
/// and credential metadata formatted for physical biometric machines (Hikvision MinMoe, ZKTeco).
class TerminalFaceTemplatePackage {
  final String employeeId;
  final String employeeName;
  final String? cardNo;
  final String faceLibType; // 'blackFD' (blocklist), 'staticFD' (standard whitelist)
  final String featureVersion; // 'V3.0', 'V5.0'
  final List<double> embeddingVector; // 128 or 512-dimensional facial embedding
  final String? photoBase64;
  final String? photoUrl;
  final Map<String, double>? faceBoundingBox; // left, top, right, bottom (0.0 - 1.0)
  final List<String> enrolledTerminalIds;
  final BiometricTemplateSyncStatus syncStatus;
  final DateTime updatedAt;

  const TerminalFaceTemplatePackage({
    required this.employeeId,
    required this.employeeName,
    this.cardNo,
    this.faceLibType = 'staticFD',
    this.featureVersion = 'V5.0',
    required this.embeddingVector,
    this.photoBase64,
    this.photoUrl,
    this.faceBoundingBox,
    this.enrolledTerminalIds = const [],
    this.syncStatus = BiometricTemplateSyncStatus.pendingPush,
    required this.updatedAt,
  });

  /// Generates the standard Hikvision ISAPI FaceDataRecord XML/JSON payload.
  Map<String, dynamic> toHikvisionFaceDataRecord({required String faceLibType}) {
    final bytes = Float32List.fromList(embeddingVector).buffer.asUint8List();
    final featureBase64 = base64Encode(bytes);

    return {
      'faceLibType': faceLibType,
      'FDID': '1',
      'FPID': employeeId,
      'name': employeeName,
      'gender': 'unknown',
      'bornTime': '1995-01-01',
      'city': 'DEFAULT',
      'certificateType': 'officerID',
      'certificateNumber': employeeId,
      'cardNo': cardNo ?? '',
      'featureData': featureBase64,
      'featureDataLen': bytes.length,
      'featureVersion': featureVersion,
      if (faceBoundingBox != null) 'faceRect': faceBoundingBox,
    };
  }

  /// Generates the standard ZKTeco ADMS BIODATA facial template payload.
  String toZkTecoBioDataRecord({required int pin}) {
    final bytes = Float32List.fromList(embeddingVector).buffer.asUint8List();
    final featureBase64 = base64Encode(bytes);

    // Format: BIODATA Pin={pin}\tNo=0\tIndex=0\tValid=1\tDuress=0\tType=9\tMajorVer=10\tMinorVer=0\tFormat=0\tTmp={featureBase64}
    return 'BIODATA Pin=$pin\tNo=0\tIndex=0\tValid=1\tDuress=0\tType=9\tMajorVer=10\tMinorVer=0\tFormat=0\tTmp=$featureBase64';
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'cardNo': cardNo,
      'faceLibType': faceLibType,
      'featureVersion': featureVersion,
      'embeddingVector': embeddingVector,
      'photoBase64': photoBase64,
      'photoUrl': photoUrl,
      'faceBoundingBox': faceBoundingBox,
      'enrolledTerminalIds': enrolledTerminalIds,
      'syncStatus': syncStatus.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TerminalFaceTemplatePackage.fromJson(Map<String, dynamic> json) {
    BiometricTemplateSyncStatus parseSyncStatus(String? name) {
      return BiometricTemplateSyncStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => BiometricTemplateSyncStatus.pendingPush,
      );
    }

    return TerminalFaceTemplatePackage(
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      cardNo: json['cardNo'] as String?,
      faceLibType: json['faceLibType'] as String? ?? 'staticFD',
      featureVersion: json['featureVersion'] as String? ?? 'V5.0',
      embeddingVector: (json['embeddingVector'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      photoBase64: json['photoBase64'] as String?,
      photoUrl: json['photoUrl'] as String?,
      faceBoundingBox: (json['faceBoundingBox'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
      enrolledTerminalIds: (json['enrolledTerminalIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      syncStatus: parseSyncStatus(json['syncStatus'] as String?),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  TerminalFaceTemplatePackage copyWith({
    String? employeeId,
    String? employeeName,
    String? cardNo,
    String? faceLibType,
    String? featureVersion,
    List<double>? embeddingVector,
    String? photoBase64,
    String? photoUrl,
    Map<String, double>? faceBoundingBox,
    List<String>? enrolledTerminalIds,
    BiometricTemplateSyncStatus? syncStatus,
    DateTime? updatedAt,
  }) {
    return TerminalFaceTemplatePackage(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      cardNo: cardNo ?? this.cardNo,
      faceLibType: faceLibType ?? this.faceLibType,
      featureVersion: featureVersion ?? this.featureVersion,
      embeddingVector: embeddingVector ?? this.embeddingVector,
      photoBase64: photoBase64 ?? this.photoBase64,
      photoUrl: photoUrl ?? this.photoUrl,
      faceBoundingBox: faceBoundingBox ?? this.faceBoundingBox,
      enrolledTerminalIds: enrolledTerminalIds ?? this.enrolledTerminalIds,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
