
enum OvertimeRequestStatus {
  pending,
  approved,
  rejected,
  autoExpired,
}

enum OvertimeCategory {
  weekdayExtra,
  weekend,
  statutoryHoliday,
}

class OvertimePreApprovalRequest {
  final String id;
  final String enterpriseId;
  final String userId;
  final String employeeName;
  final String department;
  final DateTime shiftDate;
  final double plannedHours;
  final OvertimeCategory category;
  final String justification;
  final OvertimeRequestStatus status;
  final DateTime requestedAt;
  final String? approvedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  const OvertimePreApprovalRequest({
    required this.id,
    required this.enterpriseId,
    required this.userId,
    required this.employeeName,
    required this.department,
    required this.shiftDate,
    required this.plannedHours,
    required this.category,
    required this.justification,
    this.status = OvertimeRequestStatus.pending,
    required this.requestedAt,
    this.approvedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  OvertimePreApprovalRequest copyWith({
    OvertimeRequestStatus? status,
    String? approvedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return OvertimePreApprovalRequest(
      id: id,
      enterpriseId: enterpriseId,
      userId: userId,
      employeeName: employeeName,
      department: department,
      shiftDate: shiftDate,
      plannedHours: plannedHours,
      category: category,
      justification: justification,
      status: status ?? this.status,
      requestedAt: requestedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'enterpriseId': enterpriseId,
    'userId': userId,
    'employeeName': employeeName,
    'department': department,
    'shiftDate': shiftDate.toIso8601String(),
    'plannedHours': plannedHours,
    'category': category.name,
    'justification': justification,
    'status': status.name,
    'requestedAt': requestedAt.toIso8601String(),
    'approvedBy': approvedBy,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
  };

  factory OvertimePreApprovalRequest.fromJson(Map<String, dynamic> json) {
    return OvertimePreApprovalRequest(
      id: json['id'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      department: json['department'] as String? ?? 'General',
      shiftDate: DateTime.tryParse(json['shiftDate'] as String? ?? '') ?? DateTime.now(),
      plannedHours: (json['plannedHours'] as num?)?.toDouble() ?? 1.0,
      category: OvertimeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => OvertimeCategory.weekdayExtra,
      ),
      justification: json['justification'] as String? ?? 'Project Overtime',
      status: OvertimeRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OvertimeRequestStatus.pending,
      ),
      requestedAt: DateTime.tryParse(json['requestedAt'] as String? ?? '') ?? DateTime.now(),
      approvedBy: json['approvedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null 
          ? DateTime.tryParse(json['reviewedAt'] as String) 
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}

class OvertimePreApprovalService {
  static final OvertimePreApprovalService _instance = OvertimePreApprovalService._internal();
  factory OvertimePreApprovalService() => _instance;
  OvertimePreApprovalService._internal();

  final List<OvertimePreApprovalRequest> _requests = [];

  List<OvertimePreApprovalRequest> get requests => List.unmodifiable(_requests);

  static const double maxAllowedDailyHours = 4.0;

  OvertimePreApprovalRequest submitRequest({
    required String enterpriseId,
    required String userId,
    required String employeeName,
    required String department,
    required DateTime shiftDate,
    required double plannedHours,
    required OvertimeCategory category,
    required String justification,
  }) {
    if (plannedHours <= 0) {
      throw ArgumentError('Planned overtime must be greater than 0 hours');
    }
    if (plannedHours > maxAllowedDailyHours) {
      throw ArgumentError('Planned overtime cannot exceed $maxAllowedDailyHours hours in a single shift');
    }

    final request = OvertimePreApprovalRequest(
      id: 'ot_${DateTime.now().millisecondsSinceEpoch}_$userId',
      enterpriseId: enterpriseId,
      userId: userId,
      employeeName: employeeName,
      department: department,
      shiftDate: shiftDate,
      plannedHours: plannedHours,
      category: category,
      justification: justification,
      requestedAt: DateTime.now(),
    );

    _requests.insert(0, request);
    return request;
  }

  bool approveRequest(String requestId, String managerUid) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;
    _requests[index] = _requests[index].copyWith(
      status: OvertimeRequestStatus.approved,
      approvedBy: managerUid,
      reviewedAt: DateTime.now(),
    );
    return true;
  }

  bool rejectRequest(String requestId, String managerUid, String reason) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;
    _requests[index] = _requests[index].copyWith(
      status: OvertimeRequestStatus.rejected,
      approvedBy: managerUid,
      reviewedAt: DateTime.now(),
      rejectionReason: reason,
    );
    return true;
  }

  bool hasApprovedOvertimeForDate({
    required String userId,
    required DateTime date,
  }) {
    return _requests.any((r) =>
      r.userId == userId &&
      r.status == OvertimeRequestStatus.approved &&
      r.shiftDate.year == date.year &&
      r.shiftDate.month == date.month &&
      r.shiftDate.day == date.day
    );
  }

  double getTotalApprovedHoursForDate({
    required String userId,
    required DateTime date,
  }) {
    return _requests
        .where((r) =>
            r.userId == userId &&
            r.status == OvertimeRequestStatus.approved &&
            r.shiftDate.year == date.year &&
            r.shiftDate.month == date.month &&
            r.shiftDate.day == date.day)
        .fold(0.0, (acc, r) => acc + r.plannedHours);
  }

  void clearForTesting() {
    _requests.clear();
  }
}
