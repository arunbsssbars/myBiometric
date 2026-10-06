import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequest {
  final String id;
  final String userId;
  final String enterpriseId;
  final String employeeName;
  final String employeeId;
  final String leaveType; // 'CASUAL', 'SICK', 'PAID', 'WFH', 'UNPAID'
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final String reason;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;

  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.enterpriseId,
    required this.employeeName,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.reason,
    this.status = 'PENDING',
    required this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'enterpriseId': enterpriseId.trim(),
      'employeeName': employeeName,
      'employeeId': employeeId,
      'leaveType': leaveType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'daysCount': daysCount,
      'reason': reason,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewNotes != null) 'reviewNotes': reviewNotes,
    };
  }

  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return LeaveRequest(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      enterpriseId: data['enterpriseId'] as String? ?? '',
      employeeName: data['employeeName'] as String? ?? 'Employee',
      employeeId: data['employeeId'] as String? ?? 'N/A',
      leaveType: data['leaveType'] as String? ?? 'CASUAL',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      daysCount: (data['daysCount'] as num?)?.toInt() ?? 1,
      reason: data['reason'] as String? ?? '',
      status: data['status'] as String? ?? 'PENDING',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewNotes: data['reviewNotes'] as String?,
    );
  }

  String get leaveTypeDisplay {
    switch (leaveType) {
      case 'SICK':
        return 'Sick Leave';
      case 'PAID':
        return 'Paid Leave';
      case 'WFH':
        return 'Work from Home';
      case 'UNPAID':
        return 'Unpaid Time-Off';
      case 'CASUAL':
      default:
        return 'Casual Leave';
    }
  }
}
