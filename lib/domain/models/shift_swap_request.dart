import 'package:flutter/foundation.dart';

enum ShiftSwapStatus {
  pendingPeer,
  pendingManager,
  approved,
  rejectedByPeer,
  rejectedByManager,
  cancelled,
}

@immutable
class ShiftSwapRequest {
  final String id;
  final String enterpriseId;
  final String requesterId;
  final String requesterName;
  final String requesterDepartment;
  final String requesterShiftName;
  final DateTime requesterDate;

  final String targetEmployeeId;
  final String targetEmployeeName;
  final String targetDepartment;
  final String targetShiftName;
  final DateTime targetDate;

  final String reason;
  final ShiftSwapStatus status;
  final DateTime createdAt;
  final DateTime? peerRespondedAt;
  final DateTime? managerRespondedAt;
  final String? managerUid;
  final String? managerNotes;

  const ShiftSwapRequest({
    required this.id,
    required this.enterpriseId,
    required this.requesterId,
    required this.requesterName,
    this.requesterDepartment = 'General',
    this.requesterShiftName = 'Standard Shift',
    required this.requesterDate,
    required this.targetEmployeeId,
    required this.targetEmployeeName,
    this.targetDepartment = 'General',
    this.targetShiftName = 'Standard Shift',
    required this.targetDate,
    required this.reason,
    this.status = ShiftSwapStatus.pendingPeer,
    required this.createdAt,
    this.peerRespondedAt,
    this.managerRespondedAt,
    this.managerUid,
    this.managerNotes,
  });

  bool get isPendingPeer => status == ShiftSwapStatus.pendingPeer;
  bool get isPendingManager => status == ShiftSwapStatus.pendingManager;
  bool get isApproved => status == ShiftSwapStatus.approved;
  bool get isFinalized =>
      status == ShiftSwapStatus.approved ||
      status == ShiftSwapStatus.rejectedByPeer ||
      status == ShiftSwapStatus.rejectedByManager ||
      status == ShiftSwapStatus.cancelled;

  String get statusDisplay {
    switch (status) {
      case ShiftSwapStatus.pendingPeer:
        return 'Awaiting Peer Approval';
      case ShiftSwapStatus.pendingManager:
        return 'Awaiting Manager Review';
      case ShiftSwapStatus.approved:
        return 'Approved & Confirmed';
      case ShiftSwapStatus.rejectedByPeer:
        return 'Declined by Colleague';
      case ShiftSwapStatus.rejectedByManager:
        return 'Rejected by Manager';
      case ShiftSwapStatus.cancelled:
        return 'Cancelled';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterDepartment': requesterDepartment,
      'requesterShiftName': requesterShiftName,
      'requesterDate': requesterDate.toIso8601String(),
      'targetEmployeeId': targetEmployeeId,
      'targetEmployeeName': targetEmployeeName,
      'targetDepartment': targetDepartment,
      'targetShiftName': targetShiftName,
      'targetDate': targetDate.toIso8601String(),
      'reason': reason,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'peerRespondedAt': peerRespondedAt?.toIso8601String(),
      'managerRespondedAt': managerRespondedAt?.toIso8601String(),
      'managerUid': managerUid,
      'managerNotes': managerNotes,
    };
  }

  factory ShiftSwapRequest.fromMap(Map<String, dynamic> map, {String? id}) {
    return ShiftSwapRequest(
      id: id ?? map['id']?.toString() ?? '',
      enterpriseId: map['enterpriseId']?.toString() ?? '',
      requesterId: map['requesterId']?.toString() ?? '',
      requesterName: map['requesterName']?.toString() ?? 'Requester',
      requesterDepartment: map['requesterDepartment']?.toString() ?? 'General',
      requesterShiftName: map['requesterShiftName']?.toString() ?? 'Standard Shift',
      requesterDate: DateTime.tryParse(map['requesterDate']?.toString() ?? '') ?? DateTime.now(),
      targetEmployeeId: map['targetEmployeeId']?.toString() ?? '',
      targetEmployeeName: map['targetEmployeeName']?.toString() ?? 'Target Employee',
      targetDepartment: map['targetDepartment']?.toString() ?? 'General',
      targetShiftName: map['targetShiftName']?.toString() ?? 'Standard Shift',
      targetDate: DateTime.tryParse(map['targetDate']?.toString() ?? '') ?? DateTime.now(),
      reason: map['reason']?.toString() ?? '',
      status: ShiftSwapStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ShiftSwapStatus.pendingPeer,
      ),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      peerRespondedAt: map['peerRespondedAt'] != null
          ? DateTime.tryParse(map['peerRespondedAt'].toString())
          : null,
      managerRespondedAt: map['managerRespondedAt'] != null
          ? DateTime.tryParse(map['managerRespondedAt'].toString())
          : null,
      managerUid: map['managerUid']?.toString(),
      managerNotes: map['managerNotes']?.toString(),
    );
  }

  ShiftSwapRequest copyWith({
    String? id,
    String? enterpriseId,
    String? requesterId,
    String? requesterName,
    String? requesterDepartment,
    String? requesterShiftName,
    DateTime? requesterDate,
    String? targetEmployeeId,
    String? targetEmployeeName,
    String? targetDepartment,
    String? targetShiftName,
    DateTime? targetDate,
    String? reason,
    ShiftSwapStatus? status,
    DateTime? createdAt,
    DateTime? peerRespondedAt,
    DateTime? managerRespondedAt,
    String? managerUid,
    String? managerNotes,
  }) {
    return ShiftSwapRequest(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterDepartment: requesterDepartment ?? this.requesterDepartment,
      requesterShiftName: requesterShiftName ?? this.requesterShiftName,
      requesterDate: requesterDate ?? this.requesterDate,
      targetEmployeeId: targetEmployeeId ?? this.targetEmployeeId,
      targetEmployeeName: targetEmployeeName ?? this.targetEmployeeName,
      targetDepartment: targetDepartment ?? this.targetDepartment,
      targetShiftName: targetShiftName ?? this.targetShiftName,
      targetDate: targetDate ?? this.targetDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      peerRespondedAt: peerRespondedAt ?? this.peerRespondedAt,
      managerRespondedAt: managerRespondedAt ?? this.managerRespondedAt,
      managerUid: managerUid ?? this.managerUid,
      managerNotes: managerNotes ?? this.managerNotes,
    );
  }
}
