import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/comp_time_record.dart';
import 'package:mybiometric/services/comp_time_service.dart';

void main() {
  group('CompTimeService Tests', () {
    test('Accrues comp-time with 1.5x weekend multiplier', () {
      final earned = DateTime(2026, 10, 1);
      final record = CompTimeService.accrueCompTime(
        recordId: 'comp_001',
        enterpriseId: 'ent_demo',
        userId: 'usr-1',
        employeeName: 'Dave Engineer',
        overtimeHoursWorked: 4.0,
        accrualMultiplier: 1.5,
        validityDuration: const Duration(days: 60),
        earnedDate: earned,
      );

      expect(record.earnedHours, equals(6.0));
      expect(record.remainingHours, equals(6.0));
      expect(record.expiryDate, equals(earned.add(const Duration(days: 60))));
      expect(record.getStatus(referenceDate: DateTime(2026, 10, 15)), equals(CompTimeStatus.available));
    });

    test('Calculates usable comp-time balance excluding expired records', () {
      final now = DateTime(2026, 10, 15);

      final validRecord = CompTimeRecord(
        id: '1',
        enterpriseId: 'e1',
        userId: 'u1',
        employeeName: 'Dave',
        earnedHours: 8.0,
        usedHours: 2.0, // 6 remaining
        earnedDate: DateTime(2026, 10, 1),
        expiryDate: DateTime(2026, 11, 1),
      );

      final expiredRecord = CompTimeRecord(
        id: '2',
        enterpriseId: 'e1',
        userId: 'u1',
        employeeName: 'Dave',
        earnedHours: 4.0,
        usedHours: 0.0,
        earnedDate: DateTime(2026, 8, 1),
        expiryDate: DateTime(2026, 9, 1), // Expired before now
      );

      final balance = CompTimeService.getAvailableCompTimeBalance(
        [validRecord, expiredRecord],
        referenceDate: now,
      );

      expect(balance, equals(6.0));
    });
  });
}
