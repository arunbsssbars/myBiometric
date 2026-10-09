import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/employee_profile.dart';
import 'package:mybiometric/domain/repositories/user_repository.dart';
import 'package:mybiometric/domain/use_cases/enroll_face_use_case.dart';
import 'package:mybiometric/core/utils/face_math_utils.dart';

class MockUserRepository implements UserRepository {
  final Map<String, EmployeeProfile> _profiles = {};
  bool saveCalled = false;
  String? savedUserId;
  List<double>? savedSignature;

  void addProfile(EmployeeProfile profile) {
    _profiles[profile.uid] = profile;
  }

  @override
  Stream<List<EmployeeProfile>> getEnterpriseEmployees(String enterpriseId) {
    return Stream.value(_profiles.values.where((p) => p.enterpriseId == enterpriseId).toList());
  }

  @override
  Future<List<EmployeeProfile>> getAllEnrolledBiometricProfiles() async {
    return _profiles.values.where((p) => p.biometricsEnrolled).toList();
  }

  @override
  Future<List<EmployeeProfile>> getEnterpriseEmployeesList(String enterpriseId) async {
    return _profiles.values.where((p) => p.enterpriseId == enterpriseId).toList();
  }

  @override
  Future<EmployeeProfile?> getUserProfile(String userId) async {
    return _profiles[userId];
  }

  @override
  Future<void> saveBiometricEnrollment({
    required String userId,
    required String fullName,
    required String employeeId,
    required List<double> facialSignature,
  }) async {
    saveCalled = true;
    savedUserId = userId;
    savedSignature = facialSignature;
    _profiles[userId] = EmployeeProfile(
      uid: userId,
      fullName: fullName,
      employeeId: employeeId,
      enterpriseId: 'CORP-1',
      biometricsEnrolled: true,
      facialSignature: facialSignature,
    );
  }
}

void main() {
  group('EnrollFaceUseCase Global Deduplication Suite', () {
    late MockUserRepository mockRepo;
    late EnrollFaceUseCase useCase;

    // Helper to generate a normalized 128-dimensional embedding
    List<double> generateEmbedding(double seed) {
      final list = List<double>.generate(128, (i) => (i == 0 ? seed : 0.1));
      return FaceMathUtils.l2Normalize(list);
    }

    setUp(() {
      mockRepo = MockUserRepository();
      useCase = EnrollFaceUseCase(
        userRepository: mockRepo,
        collisionThreshold: 0.60,
      );
    });

    test('Successfully enrolls novel face when no collisions exist', () async {
      final embedding = generateEmbedding(1.0);
      await useCase.execute(
        userId: 'user_1',
        fullName: 'Alice Walker',
        employeeId: 'EMP-001',
        enterpriseId: 'CORP-1',
        rawEmbeddings: [embedding],
      );

      expect(mockRepo.saveCalled, isTrue);
      expect(mockRepo.savedUserId, equals('user_1'));
      expect(mockRepo.savedSignature, isNotNull);
    });

    test('Throws BiometricCollisionException when candidate face matches existing user across enterprise', () async {
      final existingEmbedding = generateEmbedding(1.0);
      mockRepo.addProfile(EmployeeProfile(
        uid: 'user_alice',
        fullName: 'Alice Walker',
        employeeId: 'EMP-001',
        enterpriseId: 'CORP-1',
        biometricsEnrolled: true,
        facialSignature: existingEmbedding,
      ));

      // Attempt to enroll same facial signature under a different user
      final identicalEmbedding = generateEmbedding(1.0);

      expect(
        () => useCase.execute(
          userId: 'user_bob',
          fullName: 'Bob Imposter',
          employeeId: 'EMP-999',
          enterpriseId: 'CORP-1',
          rawEmbeddings: [identicalEmbedding],
        ),
        throwsA(isA<BiometricCollisionException>()),
      );
    });

    test('Allows enrollment of identical face if allowAdminAuthorizedOverwrite is true', () async {
      final existingEmbedding = generateEmbedding(1.0);
      mockRepo.addProfile(EmployeeProfile(
        uid: 'user_alice',
        fullName: 'Alice Walker',
        employeeId: 'EMP-001',
        enterpriseId: 'CORP-1',
        biometricsEnrolled: true,
        facialSignature: existingEmbedding,
      ));

      await useCase.execute(
        userId: 'user_bob',
        fullName: 'Bob Authorized',
        employeeId: 'EMP-999',
        enterpriseId: 'CORP-1',
        rawEmbeddings: [existingEmbedding],
        allowAdminAuthorizedOverwrite: true,
      );

      expect(mockRepo.saveCalled, isTrue);
      expect(mockRepo.savedUserId, equals('user_bob'));
    });

    test('Does not flag collision when user re-scans their own existing profile', () async {
      final existingEmbedding = generateEmbedding(1.0);
      mockRepo.addProfile(EmployeeProfile(
        uid: 'user_self',
        fullName: 'Self User',
        employeeId: 'EMP-007',
        enterpriseId: 'CORP-1',
        biometricsEnrolled: true,
        facialSignature: existingEmbedding,
      ));

      await useCase.execute(
        userId: 'user_self',
        fullName: 'Self User',
        employeeId: 'EMP-007',
        enterpriseId: 'CORP-1',
        rawEmbeddings: [existingEmbedding],
      );

      expect(mockRepo.saveCalled, isTrue);
      expect(mockRepo.savedUserId, equals('user_self'));
    });
  });
}
