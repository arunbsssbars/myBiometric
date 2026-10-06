import 'package:flutter/foundation.dart';

enum DeviceSyncProtocol {
  lanDirectWebSocket,
  bleMeshGatt,
  p2pWifiDirect,
}

enum SyncConflictStrategy {
  latestTimestampWins,
  trustedAdminWins,
  immutableAppendOnly,
}

/// Record exchanged during offline peer-to-peer device sync
@immutable
class DeviceMeshSyncRecord {
  final String syncBatchId;
  final String senderDeviceId;
  final String targetDeviceId;
  final DeviceSyncProtocol protocol;
  final int recordsTransferred;
  final int conflictsResolved;
  final SyncConflictStrategy strategy;
  final DateTime syncedAt;
  final bool isCompleted;

  const DeviceMeshSyncRecord({
    required this.syncBatchId,
    required this.senderDeviceId,
    required this.targetDeviceId,
    required this.protocol,
    required this.recordsTransferred,
    required this.conflictsResolved,
    required this.strategy,
    required this.syncedAt,
    this.isCompleted = true,
  });

  Map<String, dynamic> toMap() => {
        'syncBatchId': syncBatchId,
        'senderDeviceId': senderDeviceId,
        'targetDeviceId': targetDeviceId,
        'protocol': protocol.name,
        'recordsTransferred': recordsTransferred,
        'conflictsResolved': conflictsResolved,
        'strategy': strategy.name,
        'syncedAt': syncedAt.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory DeviceMeshSyncRecord.fromMap(Map<String, dynamic> map) =>
      DeviceMeshSyncRecord(
        syncBatchId: map['syncBatchId'] as String? ?? '',
        senderDeviceId: map['senderDeviceId'] as String? ?? '',
        targetDeviceId: map['targetDeviceId'] as String? ?? '',
        protocol: DeviceSyncProtocol.values.firstWhere(
          (e) => e.name == map['protocol'],
          orElse: () => DeviceSyncProtocol.lanDirectWebSocket,
        ),
        recordsTransferred: (map['recordsTransferred'] as num?)?.toInt() ?? 0,
        conflictsResolved: (map['conflictsResolved'] as num?)?.toInt() ?? 0,
        strategy: SyncConflictStrategy.values.firstWhere(
          (e) => e.name == map['strategy'],
          orElse: () => SyncConflictStrategy.latestTimestampWins,
        ),
        syncedAt: map['syncedAt'] != null
            ? DateTime.tryParse(map['syncedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        isCompleted: map['isCompleted'] as bool? ?? false,
      );
}
