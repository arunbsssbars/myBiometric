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

    // Also mirror into enterprise employees subcollection if enterpriseId is known
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final entId = userDoc.data()?['enterpriseId']?.toString();
      if (entId != null && entId.isNotEmpty) {
        await _firestore
            .collection('enterprises')
            .doc(entId)
            .collection('employees')
            .doc(userId)
            .set(updateData, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  @override
  Stream<List<EmployeeProfile>> getEnterpriseEmployees(String enterpriseId) {
    final cleanId = enterpriseId.trim();
    return _firestore
        .collection('users')
        .where('enterpriseId', isEqualTo: cleanId)
        .snapshots()
        .asyncMap((userSnapshot) async {
      final Map<String, EmployeeProfile> profileMap = {};
      for (final doc in userSnapshot.docs) {
        profileMap[doc.id] = _mapDocToProfile(doc);
      }
      try {
        final subcollectionDocs = await _firestore
            .collection('enterprises')
            .doc(cleanId)
            .collection('employees')
            .get();
        for (final doc in subcollectionDocs.docs) {
          if (!profileMap.containsKey(doc.id)) {
            profileMap[doc.id] = _mapDocToProfile(doc);
          }
        }
      } catch (_) {}
      return profileMap.values.toList();
    });
  }

  @override
  Future<List<EmployeeProfile>> getEnterpriseEmployeesList(String enterpriseId) async {
    final cleanId = enterpriseId.trim();
    final Map<String, EmployeeProfile> profileMap = {};
    try {
      final userSnapshot = await _firestore
          .collection('users')
          .where('enterpriseId', isEqualTo: cleanId)
          .get();
      for (final doc in userSnapshot.docs) {
        profileMap[doc.id] = _mapDocToProfile(doc);
      }
    } catch (_) {}

    try {
      final subcollectionDocs = await _firestore
          .collection('enterprises')
          .doc(cleanId)
          .collection('employees')
          .get();
      for (final doc in subcollectionDocs.docs) {
        if (!profileMap.containsKey(doc.id)) {
          profileMap[doc.id] = _mapDocToProfile(doc);
        }
      }
    } catch (_) {}

    return profileMap.values.toList();
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
