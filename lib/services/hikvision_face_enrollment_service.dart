import 'dart:convert';
import '../domain/models/minmoe_face_enrollment_payload.dart';

/// Service synthesizing multipart/form-data and JSON payloads for Hikvision FDLib ISAPI enrollment
class HikvisionFaceEnrollmentService {
  HikvisionFaceEnrollmentService._internal();
  static final HikvisionFaceEnrollmentService instance = HikvisionFaceEnrollmentService._internal();

  /// Generates the standard JSON metadata block for PUT /ISAPI/Intelligent/FDLib/FaceDataRecord
  Map<String, dynamic> buildFaceDataRecordJson(MinMoeFaceEnrollmentPayload payload) {
    return {
      'faceLibType': payload.faceLibType,
      'FDID': '1',
      'FPID': payload.employeeNo,
      'name': payload.employeeName,
      'gender': 'unknown',
      'bornTime': '1990-01-01',
      'city': 'Bangalore',
      'certificateType': 'officer',
      'certificateNumber': payload.cardNo,
      'caseInfo': '',
    };
  }

  /// Synthesizes the standard UserInfo payload for /ISAPI/AccessControl/UserInfo/Record
  Map<String, dynamic> buildUserInfoPayload(MinMoeFaceEnrollmentPayload payload) {
    return {
      'UserInfo': {
        'employeeNo': payload.employeeNo,
        'name': payload.employeeName,
        'userType': 'normal',
        'closeDelay': 5,
        'Valid': {
          'enable': true,
          'beginTime': DateTime.fromMillisecondsSinceEpoch(payload.validFromEpochSeconds * 1000).toIso8601String(),
          'endTime': DateTime.fromMillisecondsSinceEpoch(payload.validToEpochSeconds * 1000).toIso8601String(),
        },
        'doorRight': '1',
        'RightPlan': [
          {'doorNo': 1, 'planTemplateNo': '1'}
        ],
      }
    };
  }

  /// Creates a multipart request map ready for HTTP ISAPI dispatch
  Map<String, dynamic> prepareMultipartEnrollmentPackage(MinMoeFaceEnrollmentPayload payload) {
    final metaJson = jsonEncode(buildFaceDataRecordJson(payload));
    return {
      'partMetadataJson': metaJson,
      'faceImageBase64': payload.faceDataJpegBase64,
      'imageSizeBytes': base64Decode(payload.faceDataJpegBase64).length,
    };
  }
}
