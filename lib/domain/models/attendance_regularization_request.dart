import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_format_utils.dart';

/// Categories of attendance correction/regularization
enum RegularizationCategory {
  forgotPunch,
  clientVisit,
  deviceIssue,
  healthEmergency,
  other;

  String get label {
    switch (this) {
      case RegularizationCategory.forgotPunch:
        return 'Forgot Punch';
      case RegularizationCategory.clientVisit:
        return 'Outdoor Client Visit';
      case RegularizationCategory.deviceIssue:
        return 'Device / Network Glitch';
      case RegularizationCategory.healthEmergency:
        return 'Health / Emergency';
      case RegularizationCategory.other:
        return 'Other Reason';
    }
  }

  static RegularizationCategory fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'FORGOT_PUNCH':
        return RegularizationCategory.forgotPunch;
      case 'CLIENT_VISIT':
        return RegularizationCategory.clientVisit;
      case 'DEVICE_ISSUE':
        return RegularizationCategory.deviceIssue;
      case 'HEALTH_EMERGENCY':
        return RegularizationCategory.healthEmergency;
      default:
        return RegularizationCategory.other;
    }
  }

  String toDbString() {
    switch (this) {
      case RegularizationCategory.forgotPunch:
        return 'FORGOT_PUNCH';
      case RegularizationCategory.clientVisit:
        return 'CLIENT_VISIT';
      case RegularizationCategory.deviceIssue:
        return 'DEVICE_ISSUE';
      case RegularizationCategory.healthEmergency:
        return 'HEALTH_EMERGENCY';
      case RegularizationCategory.other:
        return 'OTHER';
    }
  }
}

/// Status of the regularization request
enum RegularizationStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case RegularizationStatus.pending:
        return 'Pending Review';
      case RegularizationStatus.approved:
        return 'Approved';
      case RegularizationStatus.rejected:
        return 'Rejected';
    }
  }

  static RegularizationStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'APPROVED':
        return RegularizationStatus.approved;
      case 'REJECTED':
        return RegularizationStatus.rejected;
      default:
        return RegularizationStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case RegularizationStatus.pending:
        return 'PENDING';
      case RegularizationStatus.approved:
        return 'APPROVED';
      case RegularizationStatus.rejected:
        return 'REJECTED';
    }
  }
}

/// Domain model representing an employee's request to correct or regularize timesheet entries.
class AttendanceRegularizationRequest {
  final String id;
  final String userId;
  final String enterpriseId;
  final String employeeName;
  final String employeeId;
  final DateTime targetDate;
  final DateTime requestedCheckIn;
  final DateTime requestedCheckOut;
  final RegularizationCategory category;
  final String reasonDescription;
  final RegularizationStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;

  const AttendanceRegularizationRequest({
    required this.id,
    required this.userId,
    required this.enterpriseId,
    required this.employeeName,
    required this.employeeId,
    required this.targetDate,
    required this.requestedCheckIn,
    required this.requestedCheckOut,
    required this.category,
    required this.reasonDescription,
    this.status = RegularizationStatus.pending,
    required this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
  });

  /// Computes the requested total duration in minutes
  int get requestedDurationMinutes {
    if (requestedCheckOut.isBefore(requestedCheckIn)) return 0;
    return requestedCheckOut.difference(requestedCheckIn).inMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'enterpriseId': enterpriseId.trim(),
      'employeeName': employeeName,
      'employeeId': employeeId,
      'targetDate': Timestamp.fromDate(targetDate),
      'requestedCheckIn': Timestamp.fromDate(requestedCheckIn),
      'requestedCheckOut': Timestamp.fromDate(requestedCheckOut),
      'category': category.toDbString(),
      'reasonDescription': reasonDescription,
      'status': status.toDbString(),
      'appliedAt': Timestamp.fromDate(appliedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewNotes != null) 'reviewNotes': reviewNotes,
    };
  }

  factory AttendanceRegularizationRequest.fromMap(
    Map<String, dynamic> data, {
    String id = '',
  }) {
    return AttendanceRegularizationRequest(
      id: id,
      userId: (data['userId'] as String?) ?? '',
      enterpriseId: (data['enterpriseId'] as String?) ?? '',
      employeeName: (data['employeeName'] as String?) ?? 'Employee',
      employeeId: (data['employeeId'] as String?) ?? '',
      targetDate: AppFormatUtils.parseTimestamp(data['targetDate']),
      requestedCheckIn: AppFormatUtils.parseTimestamp(data['requestedCheckIn']),
      requestedCheckOut: AppFormatUtils.parseTimestamp(data['requestedCheckOut']),
      category: RegularizationCategory.fromString(data['category'] as String?),
      reasonDescription: (data['reasonDescription'] as String?) ?? '',
      status: RegularizationStatus.fromString(data['status'] as String?),
      appliedAt: AppFormatUtils.parseTimestamp(data['appliedAt']),
      reviewedAt: data['reviewedAt'] != null
          ? AppFormatUtils.parseTimestamp(data['reviewedAt'])
          : null,
      reviewedBy: data['reviewedBy'] as String?,
      reviewNotes: data['reviewNotes'] as String?,
    );
  }

  factory AttendanceRegularizationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return AttendanceRegularizationRequest.fromMap(data, id: doc.id);
  }

  AttendanceRegularizationRequest copyWith({
    String? id,
    String? userId,
    String? enterpriseId,
    String? employeeName,
    String? employeeId,
    DateTime? targetDate,
    DateTime? requestedCheckIn,
    DateTime? requestedCheckOut,
    RegularizationCategory? category,
    String? reasonDescription,
    RegularizationStatus? status,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
  }) {
    return AttendanceRegularizationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      employeeName: employeeName ?? this.employeeName,
      employeeId: employeeId ?? this.employeeId,
      targetDate: targetDate ?? this.targetDate,
      requestedCheckIn: requestedCheckIn ?? this.requestedCheckIn,
      requestedCheckOut: requestedCheckOut ?? this.requestedCheckOut,
      category: category ?? this.category,
      reasonDescription: reasonDescription ?? this.reasonDescription,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }
}
