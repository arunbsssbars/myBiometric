import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/shift_differential_policy.dart';
import 'package:mybiometric_app/services/shift_differential_service.dart';

void main() {
  group('ShiftDifferentialService Tests', () {
    test('Calculates night shift hours accurately across midnight boundary', () {
      final punchIn = DateTime(2026, 10, 2, 20, 0); // 8:00 PM
      final punchOut = DateTime(2026, 10, 3, 4, 0); // 4:00 AM next day (8 hours total)

      final nightHours = ShiftDifferentialService.calculateNightShiftHours(
        punchIn: punchIn,
        punchOut: punchOut,
        nightStartHour: 22,
        nightEndHour: 6,
      );

      // From 22:00 to 04:00 is exactly 6 hours
      expect(nightHours, closeTo(6.0, 0.05));
    });

    test('Evaluates shift differential earnings with night premium multiplier', () {
      final punchIn = DateTime(2026, 10, 2, 22, 0);
      final punchOut = DateTime(2026, 10, 3, 6, 0); // 8 hours entirely at night

      const nightRule = ShiftDifferentialRule(
        id: 'rule_night_1',
        name: 'Graveyard Shift Premium',
        type: DifferentialType.nightShift,
        nightWindowStart: TimeOfDay(hour: 22, minute: 0),
        nightWindowEnd: TimeOfDay(hour: 6, minute: 0),
        rateMultiplier: 1.15, // 15% extra
        flatBonusPerHour: 2.0, // +$2/hr bonus
      );

      final result = ShiftDifferentialService.evaluateShiftDifferential(
        punchIn: punchIn,
        punchOut: punchOut,
        baseHourlyRate: 20.0,
        rules: [nightRule],
      );

      expect(result.nightHours, closeTo(8.0, 0.05));
      // Premium: 8 hrs * $20 * 0.15 ($24) + 8 hrs * $2 ($16) = $40
      expect(result.totalPremiumAmount, closeTo(40.0, 0.1));
    });
  });
}
