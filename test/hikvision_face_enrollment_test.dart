import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/minmoe_face_enrollment_payload.dart';
import 'package:mybiometric/services/hikvision_face_enrollment_service.dart';

void main() {
  group('HikvisionFaceEnrollmentService Suite', () {
    final dummyJpegBase64 = base64Encode(utf8.encode('DUMMY_JPEG_BYTES_SAMPLE'));

    final payload = MinMoeFaceEnrollmentPayload(
      employeeNo: 'EMP1001',
      employeeName: 'Sarah Connor',
      cardNo: 'CRD883311',
      faceDataJpegBase64: dummyJpegBase64,
      validFromEpochSeconds: 1700000000,
      validToEpochSeconds: 1800000000,
      enableDualAuthentication: true,
    );

    test('Synthesizes compliant FDLib FaceDataRecord metadata JSON', () {
      final json = HikvisionFaceEnrollmentService.instance.buildFaceDataRecordJson(payload);

      expect(json['FPID'], equals('EMP1001'));
      expect(json['name'], equals('Sarah Connor'));
      expect(json['certificateNumber'], equals('CRD883311'));
      expect(json['faceLibType'], equals('blackFD'));
    });

    test('Builds valid UserInfo access record payload with validity window', () {
      final userInfo = HikvisionFaceEnrollmentService.instance.buildUserInfoPayload(payload);

      expect(userInfo['UserInfo']['employeeNo'], equals('EMP1001'));
      expect(userInfo['UserInfo']['Valid']['enable'], isTrue);
      expect(userInfo['UserInfo']['doorRight'], equals('1'));
    });

    test('Prepares multipart package with decoded image size parity', () {
      final pkg = HikvisionFaceEnrollmentService.instance.prepareMultipartEnrollmentPackage(payload);

      expect(pkg['partMetadataJson'].contains('EMP1001'), isTrue);
      expect(pkg['imageSizeBytes'], greaterThan(0));
      expect(pkg['faceImageBase64'], equals(dummyJpegBase64));
    });
  });
}
