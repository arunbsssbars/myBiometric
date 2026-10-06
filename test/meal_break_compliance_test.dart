import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/meal_break_policy.dart';
import 'package:mybiometric/services/meal_break_compliance_service.dart';

void main() {
  group('MealBreakComplianceService Tests', () {
    const policy = MealBreakPolicy(
      continuousWorkThresholdMinutes: 300, // 5 hours
      minimumBreakDurationMinutes: 30,
      mealPenaltyHours: 1.0,
    );

    test('Validates compliant 8-hour shift with a 45-min lunch break after 4 hours', () {
      final punchIn = DateTime(2026, 10, 3, 9, 0);
      final breakStart = DateTime(2026, 10, 3, 13, 0); // 4 hrs in
      final breakEnd = DateTime(2026, 10, 3, 13, 45); // 45 min break
      final punchOut = DateTime(2026, 10, 3, 17, 45);

      final result = MealBreakComplianceService.evaluateShiftMealBreak(
        punchIn: punchIn,
        punchOut: punchOut,
        breakStart: breakStart,
        breakEnd: breakEnd,
        policy: policy,
      );

      expect(result.isCompliant, isTrue);
      expect(result.penaltyHoursAwarded, equals(0.0));
    });

    test('Flags penalty when mandatory meal break is completely missed on 8-hour shift', () {
      final punchIn = DateTime(2026, 10, 3, 9, 0);
      final punchOut = DateTime(2026, 10, 3, 17, 0);

      final result = MealBreakComplianceService.evaluateShiftMealBreak(
        punchIn: punchIn,
        punchOut: punchOut,
        breakStart: null,
        breakEnd: null,
        policy: policy,
      );

      expect(result.isCompliant, isFalse);
      expect(result.isMissedBreak, isTrue);
      expect(result.penaltyHoursAwarded, equals(1.0));
    });
  });
}
