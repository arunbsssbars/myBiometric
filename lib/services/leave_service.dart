import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/leave_request.dart';
import 'push_notification_service.dart';

class LeaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a new Leave / Time-Off request
  Future<void> applyLeave({required LeaveRequest request}) async {
    await _db.collection('leave_requests').add(request.toMap());

    // Send push notification to Enterprise Admin
    await PushNotificationService().sendLeaveApplicationAlert(
      enterpriseId: request.enterpriseId,
      employeeName: request.employeeName,
      leaveType: request.leaveTypeDisplay,
      daysCount: request.daysCount,
    );
  }

  /// Stream all leave requests for an enterprise (ordered newest first)
  Stream<List<LeaveRequest>> getEnterpriseLeaveRequests(String enterpriseId) {
    return _db
        .collection('leave_requests')
        .where('enterpriseId', isEqualTo: enterpriseId.trim())
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => LeaveRequest.fromFirestore(doc)).toList();
      list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return list;
    });
  }

  /// Stream leave requests for a single employee
  Stream<List<LeaveRequest>> getUserLeaveRequests(String userId) {
    return _db
        .collection('leave_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => LeaveRequest.fromFirestore(doc)).toList();
      list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return list;
    });
  }

  /// Admin approves leave request
  Future<void> approveLeave({
    required LeaveRequest request,
    required String reviewerName,
    String? reviewNotes,
  }) async {
    await _db.collection('leave_requests').doc(request.id).update({
      'status': 'APPROVED',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerName,
      'reviewNotes': reviewNotes ?? 'Approved by Administrator',
    });

    await PushNotificationService().sendLeaveReviewAlert(
      userId: request.userId,
      isApproved: true,
      leaveType: request.leaveTypeDisplay,
      reviewerNotes: reviewNotes,
    );
  }

  /// Admin rejects leave request
  Future<void> rejectLeave({
    required LeaveRequest request,
    required String reviewerName,
    String? reviewNotes,
  }) async {
    await _db.collection('leave_requests').doc(request.id).update({
      'status': 'REJECTED',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerName,
      'reviewNotes': reviewNotes ?? 'Declined by Administrator',
    });

    await PushNotificationService().sendLeaveReviewAlert(
      userId: request.userId,
      isApproved: false,
      leaveType: request.leaveTypeDisplay,
      reviewerNotes: reviewNotes,
    );
  }

  /// Get remaining leave balances for an employee based on standard annual quota:
  /// Casual: 12 days, Sick: 10 days, Annual/Earned: 15 days
  Future<Map<String, int>> getEmployeeLeaveBalances(String enterpriseId, String userId) async {
    const defaultQuotas = {
      'CASUAL': 12,
      'SICK': 10,
      'ANNUAL': 15,
      'UNPAID': 99,
    };

    final approvedLeaves = await _db
        .collection('leave_requests')
        .where('enterpriseId', isEqualTo: enterpriseId.trim())
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'APPROVED')
        .get();

    int usedCasual = 0;
    int usedSick = 0;
    int usedAnnual = 0;

    for (final doc in approvedLeaves.docs) {
      final data = doc.data();
      final type = data['leaveType'] as String? ?? 'CASUAL';
      final days = (data['daysCount'] as num?)?.toInt() ?? 1;
      if (type == 'CASUAL') usedCasual += days;
      if (type == 'SICK') usedSick += days;
      if (type == 'ANNUAL') usedAnnual += days;
    }

    return {
      'CASUAL': (defaultQuotas['CASUAL']! - usedCasual).clamp(0, defaultQuotas['CASUAL']!),
      'SICK': (defaultQuotas['SICK']! - usedSick).clamp(0, defaultQuotas['SICK']!),
      'ANNUAL': (defaultQuotas['ANNUAL']! - usedAnnual).clamp(0, defaultQuotas['ANNUAL']!),
    };
  }
}
