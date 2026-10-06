/// Policy configuration for statutory meal and rest break compliance (e.g., California Labor Code)
class MealBreakPolicy {
  final int continuousWorkThresholdMinutes; // e.g. 300 mins (5 hrs) before mandatory break
  final int minimumBreakDurationMinutes; // e.g. 30 mins
  final double mealPenaltyHours; // e.g. 1.0 hour extra pay if violated

  const MealBreakPolicy({
    this.continuousWorkThresholdMinutes = 300,
    this.minimumBreakDurationMinutes = 30,
    this.mealPenaltyHours = 1.0,
  });
}

/// Evaluation result of meal break compliance for a single shift
class MealBreakComplianceResult {
  final bool isCompliant;
  final bool isMissedBreak;
  final bool isShortBreak;
  final bool isLateBreak;
  final double penaltyHoursAwarded;
  final String complianceSummary;

  const MealBreakComplianceResult({
    required this.isCompliant,
    required this.isMissedBreak,
    required this.isShortBreak,
    required this.isLateBreak,
    required this.penaltyHoursAwarded,
    required this.complianceSummary,
  });
}
