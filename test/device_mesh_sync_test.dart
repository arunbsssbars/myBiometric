import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/device_mesh_sync_record.dart';
import 'package:mybiometric_app/services/device_mesh_sync_service.dart';

void main() {
  group('DeviceMeshSyncService Suite', () {
    test('Resolves conflicts using latest timestamp wins strategy', () {
      final punch1 = {
        'logId': 'log_01',
        'timestamp': '2026-10-05T09:00:00Z',
        'type': 'PUNCH_IN',
      };
      final punch2 = {
        'logId': 'log_02',
        'timestamp': '2026-10-05T09:05:00Z',
        'type': 'PUNCH_IN',
      };

      final winner = DeviceMeshSyncService.instance.resolvePunchConflict(
        punchA: punch1,
        punchB: punch2,
        strategy: SyncConflictStrategy.latestTimestampWins,
      );

      expect(winner['logId'], equals('log_02'));
    });

    test('Resolves conflicts using trusted admin override strategy', () {
      final punchNormal = {
        'logId': 'log_normal',
        'timestamp': '2026-10-05T10:00:00Z',
        'isAdminVerified': false,
      };
      final punchAdmin = {
        'logId': 'log_admin',
        'timestamp': '2026-10-05T09:00:00Z',
        'isAdminVerified': true,
      };

      final winner = DeviceMeshSyncService.instance.resolvePunchConflict(
        punchA: punchNormal,
        punchB: punchAdmin,
        strategy: SyncConflictStrategy.trustedAdminWins,
      );

      expect(winner['logId'], equals('log_admin'));
    });

    test('Synthesizes mesh batch record with expected metadata', () {
      final batch = DeviceMeshSyncService.instance.synthesizeMeshSyncBatch(
        senderId: 'kiosk_north',
        targetId: 'kiosk_south',
        incomingCount: 40,
        protocol: DeviceSyncProtocol.lanDirectWebSocket,
      );

      expect(batch.recordsTransferred, equals(40));
      expect(batch.conflictsResolved, equals(2));
      expect(batch.isCompleted, isTrue);
      expect(batch.protocol, equals(DeviceSyncProtocol.lanDirectWebSocket));
    });
  });
}
