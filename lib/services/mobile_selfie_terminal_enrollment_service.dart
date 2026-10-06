import '../domain/models/mobile_selfie_terminal_enrollment.dart';

/// Service provisioning mobile selfie face captures into physical machine databases (Hikvision MinMoe & ZKTeco ADMS)
class MobileSelfieTerminalEnrollmentService {
  /// Validates biometric selfie quality and prepares enrollment payload
  bool validateFaceQuality(String base64Jpeg, List<double> embeddings) {
    if (base64Jpeg.isEmpty || base64Jpeg.length < 500) {
      return false;
    }
    // Embeddings must be standard dimension (e.g., 128-d or 512-d)
    if (embeddings.isEmpty || (embeddings.length != 128 && embeddings.length != 512)) {
      return false;
    }
    return true;
  }

  /// Packages face data for Hikvision FDLib multipart upload
  Map<String, dynamic> packageHikvisionFdLibRecord(MobileSelfieTerminalEnrollment enrollment) {
    return {
      'faceLibType': 'blackFD',
      'FDID': '1',
      'FPID': enrollment.employeeId,
      'name': enrollment.employeeName,
      'gender': 'unknown',
      'faceData': enrollment.base64FaceJpeg,
    };
  }

  /// Packages face template for ZKTeco ADMS biometric push protocol
  String packageZkTecoBiophotoCommand(MobileSelfieTerminalEnrollment enrollment) {
    return 'DATA USER BIOPHOTO PIN=${enrollment.employeeId}\tNAME=${enrollment.employeeName}\tSIZE=${enrollment.base64FaceJpeg.length}';
  }

  /// Simulates syncing to both terminals
  Future<MobileSelfieTerminalEnrollment> syncEnrollmentToTerminals(
    MobileSelfieTerminalEnrollment enrollment,
  ) async {
    final valid = validateFaceQuality(
      enrollment.base64FaceJpeg,
      enrollment.faceFeatureVector,
    );
    if (!valid) return enrollment;

    return MobileSelfieTerminalEnrollment(
      enrollmentId: enrollment.enrollmentId,
      employeeId: enrollment.employeeId,
      enterpriseId: enrollment.enterpriseId,
      employeeName: enrollment.employeeName,
      base64FaceJpeg: enrollment.base64FaceJpeg,
      faceFeatureVector: enrollment.faceFeatureVector,
      isSyncedToHikvisionMinMoe: true,
      isSyncedToZkTecoAdms: true,
      enrolledAt: enrollment.enrolledAt,
    );
  }
}
