import '../domain/models/meal_break_policy.dart';

/// Service for auditing shifts for statutory meal break compliance and penalty hours
class MealBreakComplianceService {
  /// Evaluates whether a shift had a compliant meal break
  static MealBreakComplianceResult evaluateShiftMealBreak({
    required DateTime punchIn,
    required DateTime punchOut,
    DateTime? breakStart,
    DateTime? breakEnd,
    MealBreakPolicy policy = const MealBreakPolicy(),
  }) {
    final shiftDurationMinutes = punchOut.difference(punchIn).inMinutes;

    // If shift is shorter than continuous threshold, no mandatory meal break is required
    if (shiftDurationMinutes <= policy.continuousWorkThresholdMinutes) {
      return const MealBreakComplianceResult(
        isCompliant: true,
        isMissedBreak: false,
        isShortBreak: false,
        isLateBreak: false,
        penaltyHoursAwarded: 0.0,
        complianceSummary: 'Short shift: no mandatory meal break required.',
      );
    }

    // Shift requires a meal break
    if (breakStart == null || breakEnd == null) {
      return MealBreakComplianceResult(
        isCompliant: false,
        isMissedBreak: true,
        isShortBreak: false,
        isLateBreak: false,
        penaltyHoursAwarded: policy.mealPenaltyHours,
        complianceSummary: 'Violation: Mandatory meal break was missed on a ${shiftDurationMinutes ~/ 60}h shift.',
      );
    }

    final breakDurationMinutes = breakEnd.difference(breakStart).inMinutes;
    final isShort = breakDurationMinutes < policy.minimumBreakDurationMinutes;

    final workBeforeBreakMinutes = breakStart.difference(punchIn).inMinutes;
    final isLate = workBeforeBreakMinutes > policy.continuousWorkThresholdMinutes;

    if (isShort || isLate) {
      final reasons = <String>[];
      if (isShort) reasons.add('short break ($breakDurationMinutes mins < ${policy.minimumBreakDurationMinutes} mins)');
      if (isLate) reasons.add('taken late (after ${workBeforeBreakMinutes ~/ 60}h work)');

      return MealBreakComplianceResult(
        isCompliant: false,
        isMissedBreak: false,
        isShortBreak: isShort,
        isLateBreak: isLate,
        penaltyHoursAwarded: policy.mealPenaltyHours,
        complianceSummary: 'Violation: ${reasons.join(', ')}.',
      );
    }

    return const MealBreakComplianceResult(
      isCompliant: true,
      isMissedBreak: false,
      isShortBreak: false,
      isLateBreak: false,
      penaltyHoursAwarded: 0.0,
      complianceSummary: 'Compliant: Mandatory meal break taken on time.',
    );
  }
}
