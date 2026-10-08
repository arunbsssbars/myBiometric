import '../models/employee_profile.dart';

/// Contract for accessing and persisting user and employee data.
abstract class UserRepository {
  /// Enrolls or updates biometric face signatures for a given user.
  Future<void> saveBiometricEnrollment({
    required String userId,
    required String fullName,
    required String employeeId,
    required List<double> facialSignature,
  });

  /// Streams all enrolled employees belonging to the specified enterprise.
  Stream<List<EmployeeProfile>> getEnterpriseEmployees(String enterpriseId);

  /// Fetches a list of all employees belonging to the specified enterprise.
  Future<List<EmployeeProfile>> getEnterpriseEmployeesList(String enterpriseId);

  /// Fetches a specific employee profile.
  Future<EmployeeProfile?> getUserProfile(String userId);

  /// Fetches all enrolled biometric profiles across the entire platform for global deduplication.
  Future<List<EmployeeProfile>> getAllEnrolledBiometricProfiles();
}
