import 'dart:math';
import '../domain/models/device_mesh_sync_record.dart';

/// Service coordinating offline peer-to-peer sync and deterministic punch conflict resolution
class DeviceMeshSyncService {
  DeviceMeshSyncService._internal();
  static final DeviceMeshSyncService instance = DeviceMeshSyncService._internal();

  /// Resolves two conflicting attendance punches recorded offline on different terminals
  Map<String, dynamic> resolvePunchConflict({
    required Map<String, dynamic> punchA,
    required Map<String, dynamic> punchB,
    SyncConflictStrategy strategy = SyncConflictStrategy.latestTimestampWins,
  }) {
    switch (strategy) {
      case SyncConflictStrategy.latestTimestampWins:
        final tsA = DateTime.tryParse(punchA['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tsB = DateTime.tryParse(punchB['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tsA.isAfter(tsB) ? punchA : punchB;

      case SyncConflictStrategy.trustedAdminWins:
        final bool isAdminA = punchA['isAdminVerified'] == true;
        final bool isAdminB = punchB['isAdminVerified'] == true;
        if (isAdminA && !isAdminB) return punchA;
        if (isAdminB && !isAdminA) return punchB;
        // Fallback to latest
        return resolvePunchConflict(punchA: punchA, punchB: punchB, strategy: SyncConflictStrategy.latestTimestampWins);

      case SyncConflictStrategy.immutableAppendOnly:
        // Merge into multi-channel verification audit block
        final merged = Map<String, dynamic>.from(punchA);
        merged['reconciledP2P'] = true;
        merged['alternateLogId'] = punchB['logId'];
        return merged;
    }
  }

  /// Synthesizes a mesh sync batch record
  DeviceMeshSyncRecord synthesizeMeshSyncBatch({
    required String senderId,
    required String targetId,
    required int incomingCount,
    required DeviceSyncProtocol protocol,
  }) {
    final conflicts = incomingCount > 0 ? max(0, (incomingCount * 0.05).round()) : 0;
    return DeviceMeshSyncRecord(
      syncBatchId: 'mesh_${DateTime.now().millisecondsSinceEpoch}',
      senderDeviceId: senderId,
      targetDeviceId: targetId,
      protocol: protocol,
      recordsTransferred: incomingCount,
      conflictsResolved: conflicts,
      strategy: SyncConflictStrategy.latestTimestampWins,
      syncedAt: DateTime.now(),
      isCompleted: true,
    );
  }
}
