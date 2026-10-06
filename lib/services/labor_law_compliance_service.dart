import '../domain/models/labor_law_compliance.dart';

/// Labor Law Compliance & Rest Period Evaluation Service
class LaborLawComplianceService {
  /// Evaluates an employee's new punch attempt against statutory labor policy
  static ComplianceEvaluationResult evaluatePunchIn({
    required LaborLawPolicy policy,
    required DateTime punchInTime,
    DateTime? lastPunchOutTime,
    List<DateTime> recentWorkingDates = const [],
    double currentDayWorkedHours = 0.0,
    double currentWeekOvertimeHours = 0.0,
  }) {
    if (!policy.isEnabled) {
      return const ComplianceEvaluationResult(
        isCompliant: true,
        hasBlockingViolation: false,
        violations: [],
        restHoursSinceLastOut: double.infinity,
        consecutiveWorkingDays: 0,
        summaryMessage: 'Labor law compliance policy is disabled.',
      );
    }

    final violations = <ComplianceViolation>[];
    double restHours = double.infinity;

    // 1. Minimum Rest Period Check
    if (lastPunchOutTime != null) {
      final diffMinutes = punchInTime.difference(lastPunchOutTime).inMinutes;
      restHours = diffMinutes / 60.0;

      if (restHours < policy.minimumRestPeriodHours) {
        final severity = policy.enforceBlockingOnShiftPunch
            ? ComplianceSeverity.blocking
            : ComplianceSeverity.violation;

        final deficitHours = policy.minimumRestPeriodHours - restHours;
        violations.add(
          ComplianceViolation(
            ruleType: ComplianceRuleType.minimumRestPeriod,
            severity: severity,
            title: 'Insufficient Rest Period Between Shifts',
            description:
                'Employee received only ${restHours.toStringAsFixed(1)}h rest '
                '(${policy.minimumRestPeriodHours.toStringAsFixed(1)}h required). Deficit: ${deficitHours.toStringAsFixed(1)}h.',
            evaluatedAt: punchInTime,
            metadata: {
              'restHours': restHours,
              'requiredHours': policy.minimumRestPeriodHours,
              'deficitHours': deficitHours,
            },
          ),
        );
      }
    }

    // 2. Maximum Consecutive Working Days Check
    final consecutiveDays = _computeConsecutiveDays(
      targetDate: punchInTime,
      workingDates: recentWorkingDates,
    );

    if (consecutiveDays >= policy.maxConsecutiveWorkingDays) {
      violations.add(
        ComplianceViolation(
          ruleType: ComplianceRuleType.maximumConsecutiveDays,
          severity: ComplianceSeverity.violation,
          title: 'Maximum Consecutive Working Days Reached',
          description:
              'Employee has worked $consecutiveDays consecutive days without statutory 24h rest day '
              '(Limit: ${policy.maxConsecutiveWorkingDays} days).',
          evaluatedAt: punchInTime,
          metadata: {
            'consecutiveDays': consecutiveDays,
            'maxAllowed': policy.maxConsecutiveWorkingDays,
          },
        ),
      );
    }

    // 3. Daily Maximum Hours Check
    if (currentDayWorkedHours >= policy.maxDailyWorkHours) {
      violations.add(
        ComplianceViolation(
          ruleType: ComplianceRuleType.maximumDailyHours,
          severity: ComplianceSeverity.violation,
          title: 'Daily Maximum Working Hours Exceeded',
          description:
              'Employee has logged ${currentDayWorkedHours.toStringAsFixed(1)}h today '
              '(Statutory limit: ${policy.maxDailyWorkHours.toStringAsFixed(1)}h).',
          evaluatedAt: punchInTime,
          metadata: {
            'workedHours': currentDayWorkedHours,
            'limit': policy.maxDailyWorkHours,
          },
        ),
      );
    }

    // 4. Weekly Overtime Cap Check
    if (currentWeekOvertimeHours >= policy.maxWeeklyOvertimeHours) {
      violations.add(
        ComplianceViolation(
          ruleType: ComplianceRuleType.weeklyOvertimeCap,
          severity: ComplianceSeverity.warning,
          title: 'Weekly Overtime Threshold Cap Approached',
          description:
              'Employee has accumulated ${currentWeekOvertimeHours.toStringAsFixed(1)}h overtime this week '
              '(Weekly cap: ${policy.maxWeeklyOvertimeHours.toStringAsFixed(1)}h).',
          evaluatedAt: punchInTime,
          metadata: {
            'weeklyOvertime': currentWeekOvertimeHours,
            'limit': policy.maxWeeklyOvertimeHours,
          },
        ),
      );
    }

    final hasBlocking = violations.any((v) => v.severity == ComplianceSeverity.blocking);
    final isCompliant = violations.isEmpty;

    final summary = isCompliant
        ? 'Fully compliant with ${policy.jurisdictionName} statutory labor standards.'
        : '${violations.length} compliance ${violations.length == 1 ? "finding" : "findings"} detected.';

    return ComplianceEvaluationResult(
      isCompliant: isCompliant,
      hasBlockingViolation: hasBlocking,
      violations: violations,
      restHoursSinceLastOut: restHours,
      consecutiveWorkingDays: consecutiveDays,
      summaryMessage: summary,
    );
  }

  /// Calculates consecutive prior working days ending at targetDate
  static int _computeConsecutiveDays({
    required DateTime targetDate,
    required List<DateTime> workingDates,
  }) {
    if (workingDates.isEmpty) return 0;

    final uniqueNormalizedDates = workingDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order

    final today = DateTime(targetDate.year, targetDate.month, targetDate.day);
    int consecutive = 0;
    DateTime checkDate = today.subtract(const Duration(days: 1));

    while (uniqueNormalizedDates.contains(checkDate)) {
      consecutive++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return consecutive;
  }
}
