import '../domain/models/shift_automation_policy.dart';
import '../domain/models/shift_schedule.dart';

/// Result of evaluating whether an active session requires automated clock-out
class AutoClockOutDecision {
  final bool shouldClockOut;
  final DateTime? effectiveClockOutTime;
  final String? reason;
  final String verifiedVia;

  const AutoClockOutDecision({
    required this.shouldClockOut,
    this.effectiveClockOutTime,
    this.reason,
    this.verifiedVia = 'AUTO_SYSTEM_CLOCKOUT',
  });

  factory AutoClockOutDecision.noAction() => const AutoClockOutDecision(shouldClockOut: false);

  factory AutoClockOutDecision.trigger({
    required DateTime effectiveTime,
    required String reason,
  }) =>
      AutoClockOutDecision(
        shouldClockOut: true,
        effectiveClockOutTime: effectiveTime,
        reason: reason,
        verifiedVia: 'AUTO_SYSTEM_CLOCKOUT',
      );
}

/// Result of automated lunch/meal break deduction evaluation
class AutomatedBreakDeductionResult {
  final int grossWorkMinutes;
  final int autoDeductedMinutes;
  final int netPayableMinutes;
  final bool deductionApplied;
  final String? rationale;

  const AutomatedBreakDeductionResult({
    required this.grossWorkMinutes,
    required this.autoDeductedMinutes,
    required this.netPayableMinutes,
    required this.deductionApplied,
    this.rationale,
  });

  double get netPayableHours => netPayableMinutes / 60.0;
  double get grossWorkHours => grossWorkMinutes / 60.0;
}

/// Service executing automated shift closure rules and break auto-deductions (Jibble-compliant)
class ShiftAutomationService {
  /// Evaluates an open active punch to determine if an auto-clockout should be committed
  static AutoClockOutDecision evaluateAutoClockOut({
    required DateTime punchInTime,
    required DateTime currentTime,
    ShiftSchedule shift = const ShiftSchedule(),
    ShiftAutomationPolicy policy = const ShiftAutomationPolicy(),
  }) {
    if (!policy.autoClockOutEnabled) {
      return AutoClockOutDecision.noAction();
    }

    // 1. Shift End Rule: If policy is configured to clock out at scheduled shift end
    if (policy.autoClockOutAtShiftEnd) {
      final scheduledEnd = DateTime(
        punchInTime.year,
        punchInTime.month,
        punchInTime.day,
        shift.endHour,
        shift.endMinute,
      );

      // Handle overnight shift crossover
      final effectiveEnd = scheduledEnd.isBefore(punchInTime)
          ? scheduledEnd.add(const Duration(days: 1))
          : scheduledEnd;

      if (currentTime.isAfter(effectiveEnd)) {
        return AutoClockOutDecision.trigger(
          effectiveTime: effectiveEnd,
          reason: 'Auto clocked-out at scheduled shift end (${shift.endTimeFormatted})',
        );
      }
    }

    // 2. Maximum Shift Duration Cap (e.g. 12 hours)
    final elapsedDuration = currentTime.difference(punchInTime);
    final maxDuration = Duration(hours: policy.autoClockOutMaxShiftHours);

    if (elapsedDuration >= maxDuration) {
      final effectiveTime = punchInTime.add(maxDuration);
      return AutoClockOutDecision.trigger(
        effectiveTime: effectiveTime,
        reason: 'Auto clocked-out after reaching max shift cap of ${policy.autoClockOutMaxShiftHours} hours',
      );
    }

    return AutoClockOutDecision.noAction();
  }

  /// Calculates net work minutes after applying automated meal deductions when applicable
  static AutomatedBreakDeductionResult evaluateBreakDeductions({
    required int grossWorkMinutes,
    required int loggedUnpaidBreakMinutes,
    ShiftAutomationPolicy policy = const ShiftAutomationPolicy(),
  }) {
    // If employee already logged unpaid breaks, no auto-deduction is applied
    if (loggedUnpaidBreakMinutes > 0 || !policy.autoDeductLunchEnabled) {
      final net = grossWorkMinutes - loggedUnpaidBreakMinutes;
      return AutomatedBreakDeductionResult(
        grossWorkMinutes: grossWorkMinutes,
        autoDeductedMinutes: 0,
        netPayableMinutes: net > 0 ? net : 0,
        deductionApplied: false,
        rationale: loggedUnpaidBreakMinutes > 0
            ? 'Logged $loggedUnpaidBreakMinutes mins of unpaid break'
            : 'Auto-deduction disabled or not required',
      );
    }

    // If gross work exceeds threshold (e.g. 360m / 6h), deduct automated meal break
    if (grossWorkMinutes >= policy.autoDeductThresholdMinutes) {
      final net = grossWorkMinutes - policy.autoDeductLunchMinutes;
      return AutomatedBreakDeductionResult(
        grossWorkMinutes: grossWorkMinutes,
        autoDeductedMinutes: policy.autoDeductLunchMinutes,
        netPayableMinutes: net > 0 ? net : 0,
        deductionApplied: true,
        rationale:
            'Auto-deducted ${policy.autoDeductLunchMinutes}m unpaid meal break (worked ${grossWorkMinutes ~/ 60}h without logged break)',
      );
    }

    return AutomatedBreakDeductionResult(
      grossWorkMinutes: grossWorkMinutes,
      autoDeductedMinutes: 0,
      netPayableMinutes: grossWorkMinutes,
      deductionApplied: false,
      rationale: 'Shift duration below ${policy.autoDeductThresholdMinutes ~/ 60}h deduction threshold',
    );
  }
}
