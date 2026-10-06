/// Policy governing grace periods and penalties for early punch-outs
class EarlyDeparturePolicy {
  final int gracePeriodMinutes; // e.g. 5 minutes before scheduled end is acceptable
  final int halfDayThresholdMinutes; // e.g. leaving > 120 mins early triggers half-day deduction
  final bool requireReasonPrompt; // prompts employee in UI if punching out early
  final bool autoFlagForSupervisor; // automatically flags punch for supervisor review

  const EarlyDeparturePolicy({
    this.gracePeriodMinutes = 5,
    this.halfDayThresholdMinutes = 120,
    this.requireReasonPrompt = true,
    this.autoFlagForSupervisor = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'gracePeriodMinutes': gracePeriodMinutes,
      'halfDayThresholdMinutes': halfDayThresholdMinutes,
      'requireReasonPrompt': requireReasonPrompt,
      'autoFlagForSupervisor': autoFlagForSupervisor,
    };
  }

  factory EarlyDeparturePolicy.fromMap(Map<String, dynamic> map) {
    return EarlyDeparturePolicy(
      gracePeriodMinutes: (map['gracePeriodMinutes'] as num?)?.toInt() ?? 5,
      halfDayThresholdMinutes: (map['halfDayThresholdMinutes'] as num?)?.toInt() ?? 120,
      requireReasonPrompt: map['requireReasonPrompt'] ?? true,
      autoFlagForSupervisor: map['autoFlagForSupervisor'] ?? true,
    );
  }
}

/// Evaluation result for an early punch-out event
class EarlyDepartureEvaluation {
  final bool isEarly;
  final bool withinGracePeriod;
  final int earlyMinutes;
  final bool triggersHalfDay;
  final String statusLabel;

  const EarlyDepartureEvaluation({
    required this.isEarly,
    required this.withinGracePeriod,
    required this.earlyMinutes,
    required this.triggersHalfDay,
    required this.statusLabel,
  });
}
