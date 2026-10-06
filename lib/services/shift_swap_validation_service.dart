import '../domain/models/shift_swap_validation.dart';

/// Validates compliance with mandatory rest periods and double-shift overwork policies
class ShiftSwapValidationService {
  /// Validates a proposed swap against minimum rest rules (e.g. 11 consecutive hours)
  static ShiftSwapValidationResult validateSwapCompliance({
    required DateTime existingShiftEnd,
    required DateTime proposedNewShiftStart,
    required double weeklyHoursWorkedSoFar,
    required double swappedShiftDurationHours,
    int minRestHours = 11,
    double maxWeeklyHours = 48.0,
  }) {
    final violations = <String>[];

    // Check rest period
    final restDuration = proposedNewShiftStart.difference(existingShiftEnd);
    final restHours = restDuration.inMinutes / 60.0;
    final hasRestViolation = restHours < minRestHours;

    if (hasRestViolation) {
      violations.add(
        'Insufficient rest period: only ${restHours.toStringAsFixed(1)} hours rest between shifts (minimum required: $minRestHours hours).',
      );
    }

    // Check weekly overtime threshold
    final projectedWeeklyHours = weeklyHoursWorkedSoFar + swappedShiftDurationHours;
    final hasOtViolation = projectedWeeklyHours > maxWeeklyHours;

    if (hasOtViolation) {
      violations.add(
        'Weekly limit exceeded: projected hours ${projectedWeeklyHours.toStringAsFixed(1)} exceeds maximum cap of $maxWeeklyHours hours.',
      );
    }

    return ShiftSwapValidationResult(
      isValid: violations.isEmpty,
      ruleViolations: violations,
      hasRestPeriodViolation: hasRestViolation,
      hasOvertimeCapViolation: hasOtViolation,
    );
  }
}
