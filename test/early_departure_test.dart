import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/early_departure_policy.dart';
import 'package:mybiometric/services/early_departure_service.dart';

void main() {
  group('EarlyDepartureService Tests', () {
    const scheduledEnd = TimeOfDay(hour: 17, minute: 0); // 5:00 PM
    const policy = EarlyDeparturePolicy(
      gracePeriodMinutes: 10,
      halfDayThresholdMinutes: 120,
    );

    test('Identifies on-time punch-out at or after scheduled end', () {
      final onTime = DateTime(2026, 10, 3, 17, 0);
      final eval = EarlyDepartureService.evaluateDeparture(
        punchOutTime: onTime,
        scheduledEndTime: scheduledEnd,
        policy: policy,
      );
      expect(eval.isEarly, isFalse);
      expect(eval.statusLabel, equals('ON_TIME'));
    });

    test('Allows departure within grace period without half-day trigger', () {
      final insideGrace = DateTime(2026, 10, 3, 16, 55); // 5 mins early
      final eval = EarlyDepartureService.evaluateDeparture(
        punchOutTime: insideGrace,
        scheduledEndTime: scheduledEnd,
        policy: policy,
      );
      expect(eval.isEarly, isTrue);
      expect(eval.withinGracePeriod, isTrue);
      expect(eval.earlyMinutes, equals(5));
      expect(eval.triggersHalfDay, isFalse);
      expect(eval.statusLabel, equals('GRACE_PERIOD'));
    });

    test('Triggers half-day penalty when leaving past threshold', () {
      final veryEarly = DateTime(2026, 10, 3, 14, 0); // 3 hours early (180 mins)
      final eval = EarlyDepartureService.evaluateDeparture(
        punchOutTime: veryEarly,
        scheduledEndTime: scheduledEnd,
        policy: policy,
      );
      expect(eval.isEarly, isTrue);
      expect(eval.withinGracePeriod, isFalse);
      expect(eval.earlyMinutes, equals(180));
      expect(eval.triggersHalfDay, isTrue);
      expect(eval.statusLabel, equals('HALF_DAY_PENALTY'));
    });
  });
}
