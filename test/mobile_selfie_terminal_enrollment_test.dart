import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/mobile_selfie_terminal_enrollment.dart';
import 'package:mybiometric/services/mobile_selfie_terminal_enrollment_service.dart';

void main() {
  group('MobileSelfieTerminalEnrollmentService Tests', () {
    late MobileSelfieTerminalEnrollmentService service;

    setUp(() {
      service = MobileSelfieTerminalEnrollmentService();
    });

    test('validates biometric selfie and formats Hikvision and ZKTeco payloads', () async {
      final embeddings = List.generate(128, (i) => 0.1);
      final rawJpeg = 'A' * 800;

      final enrollment = MobileSelfieTerminalEnrollment(
        enrollmentId: 'ENR-01',
        employeeId: 'EMP-777',
        enterpriseId: 'CORP-A',
        employeeName: 'Sarah Jenkins',
        base64FaceJpeg: rawJpeg,
        faceFeatureVector: embeddings,
        enrolledAt: DateTime.now(),
      );

      final isValid = service.validateFaceQuality(rawJpeg, embeddings);
      expect(isValid, true);

      final hikRecord = service.packageHikvisionFdLibRecord(enrollment);
      expect(hikRecord['FPID'], 'EMP-777');
      expect(hikRecord['name'], 'Sarah Jenkins');

      final zkCommand = service.packageZkTecoBiophotoCommand(enrollment);
      expect(zkCommand.contains('PIN=EMP-777'), true);

      final synced = await service.syncEnrollmentToTerminals(enrollment);
      expect(synced.isSyncedToHikvisionMinMoe, true);
      expect(synced.isSyncedToZkTecoAdms, true);
    });

    test('rejects insufficient face photo or empty embeddings', () {
      final isValid = service.validateFaceQuality('', []);
      expect(isValid, false);
    });
  });
}
