import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/shift_swap_validation_service.dart';

void main() {
  group('ShiftSwapValidationService Tests', () {
    test('Approves compliant shift swap with ample rest and within weekly cap', () {
      final existingShiftEnd = DateTime(2026, 10, 3, 17, 0); // 5 PM
      final newShiftStart = DateTime(2026, 10, 4, 9, 0); // 9 AM next day (16 hrs rest)

      final result = ShiftSwapValidationService.validateSwapCompliance(
        existingShiftEnd: existingShiftEnd,
        proposedNewShiftStart: newShiftStart,
        weeklyHoursWorkedSoFar: 30.0,
        swappedShiftDurationHours: 8.0,
      );

      expect(result.isValid, isTrue);
      expect(result.ruleViolations, isEmpty);
      expect(result.hasRestPeriodViolation, isFalse);
    });

    test('Rejects swap violating 11-hour rest period or 48-hr weekly limit', () {
      final existingShiftEnd = DateTime(2026, 10, 3, 23, 0); // 11 PM
      final newShiftStart = DateTime(2026, 10, 4, 6, 0); // 6 AM next day (only 7 hrs rest)

      final result = ShiftSwapValidationService.validateSwapCompliance(
        existingShiftEnd: existingShiftEnd,
        proposedNewShiftStart: newShiftStart,
        weeklyHoursWorkedSoFar: 44.0,
        swappedShiftDurationHours: 8.0, // 52 hours total
      );

      expect(result.isValid, isFalse);
      expect(result.hasRestPeriodViolation, isTrue);
      expect(result.hasOvertimeCapViolation, isTrue);
      expect(result.ruleViolations.length, equals(2));
    });
  });
}
