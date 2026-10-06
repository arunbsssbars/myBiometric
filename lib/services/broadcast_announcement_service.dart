import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/enterprise_announcement.dart';

/// Service managing company-wide and department broadcast announcements.
class BroadcastAnnouncementService {
  final FirebaseFirestore? _firestore;

  BroadcastAnnouncementService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _effectiveFirestore {
    return _firestore ?? FirebaseFirestore.instance;
  }

  /// Publishes a new announcement to all or targeted employees.
  Future<String> publishAnnouncement({
    required String enterpriseId,
    required EnterpriseAnnouncement announcement,
  }) async {
    final docRef = _effectiveFirestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('announcements')
        .doc(announcement.id.isNotEmpty ? announcement.id : null);

    await docRef.set(announcement.toJson(), SetOptions(merge: true));
    return docRef.id;
  }

  /// Streams active announcements for an employee.
  Stream<List<EnterpriseAnnouncement>> streamActiveAnnouncements({
    required String enterpriseId,
    String? userRole,
  }) {
    return _effectiveFirestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('announcements')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final list = snapshot.docs
          .map((doc) => EnterpriseAnnouncement.fromFirestore(doc))
          .where((a) {
        if (a.expiresAt != null && a.expiresAt!.isBefore(now)) return false;
        if (a.targetRoles.isNotEmpty && userRole != null && !a.targetRoles.contains(userRole)) {
          return false;
        }
        return true;
      }).toList();

      list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return list;
    });
  }

  /// Marks an announcement as read by a specific user.
  Future<void> markAsRead({
    required String enterpriseId,
    required String announcementId,
    required String userId,
  }) async {
    try {
      await _effectiveFirestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('announcements')
          .doc(announcementId)
          .update({
        'readByUids': FieldValue.arrayUnion([userId]),
      });
    } catch (_) {}
  }
}
