import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/employee_profile.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;

  UserRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveBiometricEnrollment({
    required String userId,
    required String fullName,
    required String employeeId,
    required List<double> facialSignature,
  }) async {
    final Map<String, dynamic> updateData = {
      'fullName': fullName,
      'employeeId': employeeId,
      'facialSignature': facialSignature,
      'facialEmbedding': facialSignature, // backward compatibility
      'biometricsEnrolled': true,
      'biometricEnrolledAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .set(updateData, SetOptions(merge: true));
  }

  @override
  Stream<List<EmployeeProfile>> getEnterpriseEmployees(String enterpriseId) {
    return _firestore
        .collection('users')
        .where('enterpriseId', isEqualTo: enterpriseId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _mapDocToProfile(doc)).toList();
    });
  }

  @override
  Future<List<EmployeeProfile>> getEnterpriseEmployeesList(String enterpriseId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('enterpriseId', isEqualTo: enterpriseId)
        .get();

    return snapshot.docs.map((doc) => _mapDocToProfile(doc)).toList();
  }

  @override
  Future<EmployeeProfile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _mapDocToProfile(doc);
  }

  EmployeeProfile _mapDocToProfile(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final rawSig = data['facialSignature'] ?? data['facialEmbedding'];
    List<double>? signature;
    if (rawSig != null) {
      signature = List<double>.from(rawSig);
    }

    String name = (data['fullName'] as String?)?.trim() ?? '';
    if (name.isEmpty) name = (data['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) name = (data['displayName'] as String?)?.trim() ?? '';
    if (name.isEmpty) name = (data['email'] as String?)?.split('@').first ?? 'Employee';

    return EmployeeProfile(
      uid: doc.id,
      fullName: name,
      employeeId: data['employeeId'] ?? '',
      enterpriseId: data['enterpriseId'] ?? '',
      facialSignature: signature,
      biometricsEnrolled: data['biometricsEnrolled'] == true,
      biometricEnrolledAt: (data['biometricEnrolledAt'] as Timestamp?)?.toDate(),
    );
  }
}
