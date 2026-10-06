import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/attendance_regularization_request.dart';
import 'push_notification_service.dart';

/// Service managing employee attendance regularization requests, timesheet corrections,
/// administrative reviews, and automated attendance record creation.
class AttendanceRegularizationService {
  final FirebaseFirestore? _db;
  final PushNotificationService? _notificationService;

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;
  PushNotificationService get _notifications =>
      _notificationService ?? PushNotificationService();

  AttendanceRegularizationService({
    FirebaseFirestore? db,
    PushNotificationService? notificationService,
  })  : _db = db,
        _notificationService = notificationService;

  /// Validates a regularization request before submission.
  /// Returns null if valid, or a descriptive error message if invalid.
  static String? validate(AttendanceRegularizationRequest request) {
    if (request.userId.trim().isEmpty) {
      return 'User ID is required.';
    }
    if (request.enterpriseId.trim().isEmpty) {
      return 'Enterprise ID is required.';
    }
    if (request.requestedCheckOut.isBefore(request.requestedCheckIn)) {
      return 'Check-out time must be after check-in time.';
    }
    if (request.requestedCheckOut.isAtSameMomentAs(request.requestedCheckIn)) {
      return 'Check-in and check-out cannot be identical.';
    }
    final duration = request.requestedCheckOut.difference(request.requestedCheckIn);
    if (duration.inMinutes < 15) {
      return 'Requested shift duration must be at least 15 minutes.';
    }
    if (duration.inHours > 24) {
      return 'Requested shift duration cannot exceed 24 hours.';
    }
    if (request.reasonDescription.trim().length < 5) {
      return 'Please provide a clear reason (minimum 5 characters).';
    }
    return null;
  }

  /// Instance method for validateRequest
  String? validateRequest(AttendanceRegularizationRequest request) => validate(request);

  /// Submits an attendance regularization request and notifies administrators.
  Future<String> submitRegularizationRequest({
    required AttendanceRegularizationRequest request,
  }) async {
    final validationError = validate(request);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final docRef = await _firestore.collection('regularization_requests').add(request.toMap());

    // Send push notification to Enterprise Admin
    await _notifications.sendRegularizationRequestNotification(
      enterpriseId: request.enterpriseId,
      employeeName: request.employeeName,
      employeeId: request.employeeId,
      shiftDate: request.targetDate,
      reason: '${request.category.label}: ${request.reasonDescription}',
    );

    return docRef.id;
  }

  /// Streams all regularization requests for an enterprise (sorted newest first).
  Stream<List<AttendanceRegularizationRequest>> getEnterpriseRegularizationRequests(
    String enterpriseId,
  ) {
    return _firestore
        .collection('regularization_requests')
        .where('enterpriseId', isEqualTo: enterpriseId.trim())
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AttendanceRegularizationRequest.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return list;
    });
  }

  /// Streams regularization requests for a specific employee.
  Stream<List<AttendanceRegularizationRequest>> getUserRegularizationRequests(
    String userId,
  ) {
    return _firestore
        .collection('regularization_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AttendanceRegularizationRequest.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return list;
    });
  }

  /// Review (approve or reject) a regularization request.
  Future<void> reviewRegularizationRequest({
    required AttendanceRegularizationRequest request,
    required bool approve,
    required String reviewerName,
    String? reviewNotes,
  }) async {
    final newStatus = approve ? 'APPROVED' : 'REJECTED';

    await _firestore.collection('regularization_requests').doc(request.id).update({
      'status': newStatus,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerName,
      'reviewNotes': reviewNotes ?? (approve ? 'Approved by Admin' : 'Declined by Admin'),
    });

    // If approved, create the regularized attendance logs
    if (approve) {
      // 1. Create Regularized Punch-In Log
      await _firestore.collection('attendance_logs').add({
        'userId': request.userId,
        'enterpriseId': request.enterpriseId,
        'employeeName': request.employeeName,
        'employeeId': request.employeeId,
        'type': 'PUNCH_IN',
        'timestamp': Timestamp.fromDate(request.requestedCheckIn),
        'verifiedVia': 'REGULARIZED_BY_ADMIN',
        'isRegularized': true,
        'regularizationId': request.id,
        'regularizedBy': reviewerName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Create Regularized Punch-Out Log
      await _firestore.collection('attendance_logs').add({
        'userId': request.userId,
        'enterpriseId': request.enterpriseId,
        'employeeName': request.employeeName,
        'employeeId': request.employeeId,
        'type': 'PUNCH_OUT',
        'timestamp': Timestamp.fromDate(request.requestedCheckOut),
        'verifiedVia': 'REGULARIZED_BY_ADMIN',
        'isRegularized': true,
        'regularizationId': request.id,
        'regularizedBy': reviewerName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Send notification to user
    await _notifications.sendRegularizationStatusNotification(
      userId: request.userId,
      isApproved: approve,
      shiftDate: request.targetDate,
      reason: reviewNotes,
    );
  }

  /// Computes summary statistics from a list of regularization requests.
  static RegularizationSummary computeSummary(
    List<AttendanceRegularizationRequest> requests,
  ) {
    int total = requests.length;
    int pending = 0;
    int approved = 0;
    int rejected = 0;
    int totalMinutesApproved = 0;

    for (final r in requests) {
      switch (r.status) {
        case RegularizationStatus.pending:
          pending++;
          break;
        case RegularizationStatus.approved:
          approved++;
          totalMinutesApproved += r.requestedDurationMinutes;
          break;
        case RegularizationStatus.rejected:
          rejected++;
          break;
      }
    }

    return RegularizationSummary(
      totalCount: total,
      pendingCount: pending,
      approvedCount: approved,
      rejectedCount: rejected,
      totalApprovedDurationMinutes: totalMinutesApproved,
    );
  }
}

/// Value object summarizing regularization metrics.
class RegularizationSummary {
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int totalApprovedDurationMinutes;

  const RegularizationSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.totalApprovedDurationMinutes,
  });

  double get approvalRatePercent =>
      totalCount > 0 ? (approvedCount / totalCount) * 100.0 : 0.0;
}
