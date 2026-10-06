import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/terminal_sync_session_record.dart';

void main() {
  group('Terminal Sync Background Worker & History Suite', () {
    test('TerminalSyncSessionRecord serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 1, 14, 0);
      final completed = now.add(const Duration(seconds: 4));

      final record = TerminalSyncSessionRecord(
        id: 'sync-001',
        deviceId: 'term-gate-1',
        enterpriseId: 'ent-hq',
        startedAt: now,
        completedAt: completed,
        status: TerminalSyncStatus.success,
        trigger: TerminalSyncTrigger.scheduledCron,
        eventsFetched: 45,
        eventsSynced: 40,
        duplicatesFiltered: 5,
      );

      expect(record.duration?.inSeconds, 4);

      final map = record.toMap();
      expect(map['id'], 'sync-001');
      expect(map['eventsFetched'], 45);
      expect(map['eventsSynced'], 40);
      expect(map['duplicatesFiltered'], 5);
      expect(map['status'], 'success');
      expect(map['trigger'], 'scheduledCron');

      final revived = TerminalSyncSessionRecord.fromMap(map, id: 'sync-001');
      expect(revived.deviceId, 'term-gate-1');
      expect(revived.eventsFetched, 45);
      expect(revived.eventsSynced, 40);
      expect(revived.duplicatesFiltered, 5);
      expect(revived.status, TerminalSyncStatus.success);
      expect(revived.trigger, TerminalSyncTrigger.scheduledCron);
    });

    test('TerminalSyncSessionRecord handles error messages and partial status', () {
      final record = TerminalSyncSessionRecord(
        id: 'sync-err-1',
        deviceId: 'term-gate-2',
        enterpriseId: 'ent-hq',
        startedAt: DateTime.now(),
        status: TerminalSyncStatus.failed,
        trigger: TerminalSyncTrigger.manualAdmin,
        errorMessage: 'Connection timed out (192.168.1.200:80)',
      );

      final map = record.toMap();
      expect(map['errorMessage'], contains('Connection timed out'));
      expect(map['status'], 'failed');

      final revived = TerminalSyncSessionRecord.fromMap(map, id: 'sync-err-1');
      expect(revived.status, TerminalSyncStatus.failed);
      expect(revived.errorMessage, contains('Connection timed out'));
    });
  });
}
