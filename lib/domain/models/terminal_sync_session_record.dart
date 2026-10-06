import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_format_utils.dart';

/// Status of a terminal synchronization cycle.
enum TerminalSyncStatus {
  success,
  partial,
  failed,
  running,
}

/// Trigger source for the synchronization execution.
enum TerminalSyncTrigger {
  scheduledCron,
  manualAdmin,
  webhookPush,
  deviceHeartbeat,
}

/// Immutable domain model representing a completed or in-progress sync session.
class TerminalSyncSessionRecord {
  final String id;
  final String deviceId;
  final String enterpriseId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final TerminalSyncStatus status;
  final TerminalSyncTrigger trigger;
  final int eventsFetched;
  final int eventsSynced;
  final int duplicatesFiltered;
  final String? errorMessage;

  const TerminalSyncSessionRecord({
    required this.id,
    required this.deviceId,
    required this.enterpriseId,
    required this.startedAt,
    this.completedAt,
    this.status = TerminalSyncStatus.success,
    this.trigger = TerminalSyncTrigger.scheduledCron,
    this.eventsFetched = 0,
    this.eventsSynced = 0,
    this.duplicatesFiltered = 0,
    this.errorMessage,
  });

  Duration? get duration => completedAt?.difference(startedAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'enterpriseId': enterpriseId,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status.name,
      'trigger': trigger.name,
      'eventsFetched': eventsFetched,
      'eventsSynced': eventsSynced,
      'duplicatesFiltered': duplicatesFiltered,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  factory TerminalSyncSessionRecord.fromMap(Map<String, dynamic> map, {required String id}) {
    return TerminalSyncSessionRecord(
      id: id,
      deviceId: (map['deviceId'] ?? '').toString(),
      enterpriseId: (map['enterpriseId'] ?? '').toString(),
      startedAt: AppFormatUtils.parseTimestamp(map['startedAt']),
      completedAt: AppFormatUtils.parseTimestamp(map['completedAt']),
      status: TerminalSyncStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TerminalSyncStatus.success,
      ),
      trigger: TerminalSyncTrigger.values.firstWhere(
        (e) => e.name == map['trigger'],
        orElse: () => TerminalSyncTrigger.scheduledCron,
      ),
      eventsFetched: (map['eventsFetched'] as num?)?.toInt() ?? 0,
      eventsSynced: (map['eventsSynced'] as num?)?.toInt() ?? 0,
      duplicatesFiltered: (map['duplicatesFiltered'] as num?)?.toInt() ?? 0,
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
