import '../../core/utils/face_math_utils.dart';
import '../models/employee_profile.dart';
import '../repositories/user_repository.dart';

/// Exception thrown when a user tries to enroll a face that is already registered
/// to another employee in the enterprise.
class BiometricCollisionException implements Exception {
  final EmployeeProfile matchedEmployee;
  final double similarity;

  BiometricCollisionException({
    required this.matchedEmployee,
    required this.similarity,
  });

  @override
  String toString() =>
      'Biometric Identity Conflict: This face is already enrolled to ${matchedEmployee.fullName} (ID: ${matchedEmployee.employeeId}).';
}

/// Business logic for enrolling a user's biometric facial signature.
class EnrollFaceUseCase {
  final UserRepository _userRepository;
  final double collisionThreshold;

  EnrollFaceUseCase({
    required UserRepository userRepository,
    this.collisionThreshold = 0.72,
  }) : _userRepository = userRepository;

  Future<void> execute({
    required String userId,
    required String fullName,
    required String employeeId,
    String enterpriseId = '',
    required List<List<double>> rawEmbeddings,
    bool allowAdminAuthorizedOverwrite = false,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    if (rawEmbeddings.isEmpty) {
      throw ArgumentError('At least one face embedding sample is required for enrollment');
    }

    // 1. Average and L2-normalize all collected frames for a robust facial signature template
    final List<double> finalSignature = rawEmbeddings.length == 1
        ? FaceMathUtils.l2Normalize(rawEmbeddings.first)
        : FaceMathUtils.averageAndNormalize(rawEmbeddings);

    if (finalSignature.isEmpty) {
      throw StateError('Failed to produce a valid facial signature vector');
    }

    // 2. 1:N Biometric Deduplication Collision Check
    if (enterpriseId.isNotEmpty && !allowAdminAuthorizedOverwrite) {
      final candidates = await _userRepository.getEnterpriseEmployeesList(enterpriseId);
      for (final candidate in candidates) {
        // Exclude the current user themselves
        if (candidate.uid == userId) continue;

        final candidateSig = candidate.facialSignature;
        if (candidateSig == null || candidateSig.isEmpty) continue;

        final normalizedCandidateSig = FaceMathUtils.l2Normalize(candidateSig);
        final similarity = FaceMathUtils.cosineSimilarity(finalSignature, normalizedCandidateSig);

        if (similarity >= collisionThreshold) {
          throw BiometricCollisionException(
            matchedEmployee: candidate,
            similarity: similarity,
          );
        }
      }
    }

    // 3. Atomically persist biometric enrollment
    await _userRepository.saveBiometricEnrollment(
      userId: userId,
      fullName: fullName,
      employeeId: employeeId,
      facialSignature: finalSignature,
    );
  }
}
