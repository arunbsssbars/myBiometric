import 'package:flutter/foundation.dart';

/// Item in offline queue destined for terminal push
@immutable
class MobileQueuedTerminalPunch {
  final String punchId;
  final String employeeId;
  final String enterpriseId;
  final String punchType;
  final DateTime localPunchTime;
  final bool synced;

  const MobileQueuedTerminalPunch({
    required this.punchId,
    required this.employeeId,
    required this.enterpriseId,
    required this.punchType,
    required this.localPunchTime,
    this.synced = false,
  });

  Map<String, dynamic> toMap() => {
        'punchId': punchId,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'punchType': punchType,
        'localPunchTime': localPunchTime.toIso8601String(),
        'synced': synced,
      };

  factory MobileQueuedTerminalPunch.fromMap(Map<String, dynamic> map) =>
      MobileQueuedTerminalPunch(
        punchId: map['punchId'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        punchType: map['punchType'] as String? ?? 'PUNCH_IN',
        localPunchTime: map['localPunchTime'] != null
            ? DateTime.tryParse(map['localPunchTime'] as String) ?? DateTime.now()
            : DateTime.now(),
        synced: map['synced'] as bool? ?? false,
      );
}

/// Batch container for offline punches waiting to drain to terminal
@immutable
class MobileTerminalSyncBatch {
  final String batchId;
  final List<MobileQueuedTerminalPunch> punches;
  final DateTime createdAt;

  const MobileTerminalSyncBatch({
    required this.batchId,
    required this.punches,
    required this.createdAt,
  });

  int get pendingCount => punches.where((p) => !p.synced).length;
}
