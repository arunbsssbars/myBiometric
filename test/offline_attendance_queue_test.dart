import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mybiometric/services/offline_attendance_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineAttendanceQueueService Tests', () {
    late OfflineAttendanceQueueService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = OfflineAttendanceQueueService();
      await service.clearQueue();
    });

    test('Generates deterministic punch signature for deduplication', () {
      final punch1 = {
        'userId': 'usr-101',
        'type': 'PUNCH_IN',
        'timestamp': '2026-10-03T09:00:00.000Z',
      };
      final punch2 = {
        'userId': 'usr-101',
        'type': 'PUNCH_IN',
        'timestamp': '2026-10-03T09:00:00.000Z',
      };

      final sig1 = OfflineAttendanceQueueService.generatePunchSignature(punch1);
      final sig2 = OfflineAttendanceQueueService.generatePunchSignature(punch2);

      expect(sig1, equals(sig2));
      expect(sig1, equals('usr-101_PUNCH_IN_2026-10-03T09:00:00.000Z'));
    });

    test('Enqueues punches and deduplicates repeated identical punches', () async {
      await service.enqueuePunch({
        'userId': 'usr-101',
        'type': 'PUNCH_IN',
        'timestamp': '2026-10-03T09:00:00.000Z',
      });
      await service.enqueuePunch({
        'userId': 'usr-101',
        'type': 'PUNCH_IN',
        'timestamp': '2026-10-03T09:00:00.000Z',
      });
      await service.enqueuePunch({
        'userId': 'usr-102',
        'type': 'PUNCH_IN',
        'timestamp': '2026-10-03T09:05:00.000Z',
      });

      final initialPunches = await service.getPendingPunches();
      expect(initialPunches.length, equals(3));

      final removedCount = await service.deduplicatePendingPunches();
      expect(removedCount, equals(1));

      final deduplicated = await service.getPendingPunches();
      expect(deduplicated.length, equals(2));
      expect(service.pendingCountNotifier.value, equals(2));
    });

    test('Applies clock drift compensation offset accurately', () async {
      final baseTime = DateTime(2026, 10, 3, 10, 0, 0);
      await service.enqueuePunch({
        'userId': 'usr-101',
        'type': 'PUNCH_IN',
        'timestamp': baseTime.toIso8601String(),
      });

      const offset = Duration(minutes: 5);
      final adjustedCount = await service.applyClockDriftCompensation(offset);
      expect(adjustedCount, equals(1));

      final punches = await service.getPendingPunches();
      final adjustedDt = DateTime.parse(punches.first['timestamp']);
      expect(adjustedDt, equals(baseTime.add(offset)));
      expect(punches.first['clockDriftAdjustedMs'], equals(300000));
    });
  });
}
