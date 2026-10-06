import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/labor_law_compliance.dart';
import 'package:mybiometric_app/services/labor_law_compliance_service.dart';

void main() {
  group('LaborLawComplianceService & Rest Enforcement Tests', () {
    const policy = LaborLawPolicy(
      policyId: 'pol-eu-standard',
      enterpriseId: 'ent-1',
      jurisdictionName: 'EU Working Time Directive',
      minimumRestPeriodHours: 11.0,
      maxConsecutiveWorkingDays: 6,
      maxDailyWorkHours: 12.0,
      maxWeeklyOvertimeHours: 16.0,
      enforceBlockingOnShiftPunch: true,
    );

    test('Reports compliant when punch in satisfies 11-hour rest period', () {
      final punchOut = DateTime(2026, 10, 5, 18, 0); // 6:00 PM
      final punchIn = DateTime(2026, 10, 6, 8, 0); // 8:00 AM next day (14h rest)

      final res = LaborLawComplianceService.evaluatePunchIn(
        policy: policy,
        punchInTime: punchIn,
        lastPunchOutTime: punchOut,
      );

      expect(res.isCompliant, isTrue);
      expect(res.hasBlockingViolation, isFalse);
      expect(res.violations, isEmpty);
      expect(res.restHoursSinceLastOut, equals(14.0));
    });

    test('Flags blocking violation when rest interval is less than 11 hours and policy enforces blocking', () {
      final punchOut = DateTime(2026, 10, 5, 23, 0); // 11:00 PM
      final punchIn = DateTime(2026, 10, 6, 6, 0); // 6:00 AM next day (7h rest)

      final res = LaborLawComplianceService.evaluatePunchIn(
        policy: policy,
        punchInTime: punchIn,
        lastPunchOutTime: punchOut,
      );

      expect(res.isCompliant, isFalse);
      expect(res.hasBlockingViolation, isTrue);
      expect(res.violations.length, equals(1));
      expect(res.violations.first.ruleType, equals(ComplianceRuleType.minimumRestPeriod));
      expect(res.violations.first.severity, equals(ComplianceSeverity.blocking));
      expect(res.violations.first.title, contains('Insufficient Rest Period'));
    });

    test('Detects violation when consecutive working days reach or exceed limit', () {
      final today = DateTime(2026, 10, 7);
      // Worked preceding 6 consecutive days: Oct 1, 2, 3, 4, 5, 6
      final recentDates = List.generate(
        6,
        (i) => DateTime(2026, 10, 6 - i),
      );

      final res = LaborLawComplianceService.evaluatePunchIn(
        policy: policy,
        punchInTime: today,
        recentWorkingDates: recentDates,
      );

      expect(res.isCompliant, isFalse);
      expect(
        res.violations.any((v) => v.ruleType == ComplianceRuleType.maximumConsecutiveDays),
        isTrue,
      );
    });

    test('Detects daily hours exceeded and weekly overtime warnings', () {
      final today = DateTime(2026, 10, 5, 10, 0);

      final res = LaborLawComplianceService.evaluatePunchIn(
        policy: policy,
        punchInTime: today,
        currentDayWorkedHours: 13.5, // limit 12.0
        currentWeekOvertimeHours: 18.0, // cap 16.0
      );

      expect(res.isCompliant, isFalse);
      expect(res.violations.length, equals(2));
      expect(
        res.violations.any((v) => v.ruleType == ComplianceRuleType.maximumDailyHours),
        isTrue,
      );
      expect(
        res.violations.any((v) => v.ruleType == ComplianceRuleType.weeklyOvertimeCap),
        isTrue,
      );
    });

    test('Serializes and deserializes ComplianceViolation cleanly', () {
      final violation = ComplianceViolation(
        ruleType: ComplianceRuleType.minimumRestPeriod,
        severity: ComplianceSeverity.blocking,
        title: 'Insufficient Rest',
        description: 'Rest deficit of 3 hours',
        evaluatedAt: DateTime(2026, 10, 5),
        metadata: {'deficit': 3.0},
      );

      final map = violation.toMap();
      final revived = ComplianceViolation.fromMap(map);
      expect(revived.ruleType, equals(violation.ruleType));
      expect(revived.severity, equals(violation.severity));
      expect(revived.title, equals(violation.title));
      expect(revived.metadata['deficit'], equals(3.0));
    });
  });
}
