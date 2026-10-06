import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/labor_compliance_policy.dart';
import 'package:mybiometric/services/compliance_audit_service.dart';

void main() {
  group('Labor Compliance Domain & Audit Engine Suite', () {
    test('LaborCompliancePolicy serializes and deserializes accurately with default statutory standards', () {
      final defaultPolicy = LaborCompliancePolicy.defaultPolicy();

      expect(defaultPolicy.minRestHoursBetweenShifts, 11.0);
      expect(defaultPolicy.maxConsecutiveWorkdays, 6);
      expect(defaultPolicy.maxWeeklyWorkHours, 48.0);
      expect(defaultPolicy.maxDailyWorkHours, 12.0);
      expect(defaultPolicy.isEnforced, isTrue);

      final map = defaultPolicy.toMap();
      final reconstructed = LaborCompliancePolicy.fromMap(map);

      expect(reconstructed.minRestHoursBetweenShifts, 11.0);
      expect(reconstructed.maxConsecutiveWorkdays, 6);
      expect(reconstructed.maxWeeklyWorkHours, 48.0);
      expect(reconstructed.maxDailyWorkHours, 12.0);
      expect(reconstructed.isEnforced, isTrue);
    });

    test('ComplianceIncident correctly maps issue titles and deserializes', () {
      final incident = ComplianceIncident(
        id: 'INC_001',
        employeeId: 'EMP_001',
        employeeName: 'Sarah Connor',
        issueType: ComplianceIssueType.insufficientRestBetweenShifts,
        severity: ComplianceSeverity.violation,
        description: 'Only 8 hours rest between shifts',
        timestamp: DateTime(2026, 10, 1, 8, 0),
        metricValue: 8.0,
        thresholdValue: 11.0,
      );

      expect(incident.issueTitle, 'Insufficient Rest Between Shifts');
      final map = incident.toMap();
      final parsed = ComplianceIncident.fromMap(map);

      expect(parsed.id, 'INC_001');
      expect(parsed.employeeId, 'EMP_001');
      expect(parsed.issueType, ComplianceIssueType.insufficientRestBetweenShifts);
      expect(parsed.severity, ComplianceSeverity.violation);
      expect(parsed.metricValue, 8.0);
    });

    test('ComplianceAuditService detects insufficient rest gap between consecutive shifts', () {
      final service = ComplianceAuditService();
      final roster = [
        {'id': 'EMP_101', 'fullName': 'Alice Smith'},
      ];

      // Day 1: Shift ends at 22:00 (10 PM)
      // Day 2: Next shift begins at 06:00 (6 AM) -> Rest = 8 hours (< 11h statutory requirement)
      final logs = [
        {
          'userId': 'EMP_101',
          'timestamp': DateTime(2026, 10, 1, 14, 0).toIso8601String(),
          'type': 'PUNCH_IN',
        },
        {
          'userId': 'EMP_101',
          'timestamp': DateTime(2026, 10, 1, 22, 0).toIso8601String(),
          'type': 'PUNCH_OUT',
        },
        {
          'userId': 'EMP_101',
          'timestamp': DateTime(2026, 10, 2, 6, 0).toIso8601String(),
          'type': 'PUNCH_IN',
        },
        {
          'userId': 'EMP_101',
          'timestamp': DateTime(2026, 10, 2, 14, 0).toIso8601String(),
          'type': 'PUNCH_OUT',
        },
      ];

      final report = service.auditCompliance(
        roster: roster,
        logs: logs,
        policy: const LaborCompliancePolicy(minRestHoursBetweenShifts: 11.0),
      );

      expect(report.totalViolations, 1);
      expect(report.incidents.length, 1);
      expect(report.incidents.first.issueType, ComplianceIssueType.insufficientRestBetweenShifts);
      expect(report.incidents.first.severity, ComplianceSeverity.violation);
      expect(report.complianceScorePercent, lessThan(100.0));
    });

    test('ComplianceAuditService detects excessive consecutive workdays limit (> 6 days)', () {
      final service = ComplianceAuditService();
      final roster = [
        {'id': 'EMP_102', 'fullName': 'Bob Builder'},
      ];

      // 7 consecutive days of work
      final List<Map<String, dynamic>> logs = [];
      for (int day = 1; day <= 7; day++) {
        logs.add({
          'userId': 'EMP_102',
          'timestamp': DateTime(2026, 10, day, 9, 0).toIso8601String(),
          'type': 'PUNCH_IN',
        });
        logs.add({
          'userId': 'EMP_102',
          'timestamp': DateTime(2026, 10, day, 17, 0).toIso8601String(),
          'type': 'PUNCH_OUT',
        });
      }

      final report = service.auditCompliance(
        roster: roster,
        logs: logs,
        policy: const LaborCompliancePolicy(maxConsecutiveWorkdays: 6, minRestHoursBetweenShifts: 11.0),
      );

      final consecViolations = report.incidents.where((i) => i.issueType == ComplianceIssueType.excessiveConsecutiveDays).toList();
      expect(consecViolations.length, 1);
      expect(consecViolations.first.severity, ComplianceSeverity.violation);
    });

    test('ComplianceAuditService awards 100% score for compliant shift schedule', () {
      final service = ComplianceAuditService();
      final roster = [
        {'id': 'EMP_103', 'fullName': 'Carol Danvers'},
      ];

      // Day 1 & Day 2: 9 AM to 5 PM with 16h rest gap (Compliant)
      final logs = [
        {
          'userId': 'EMP_103',
          'timestamp': DateTime(2026, 10, 1, 9, 0).toIso8601String(),
          'type': 'PUNCH_IN',
        },
        {
          'userId': 'EMP_103',
          'timestamp': DateTime(2026, 10, 1, 17, 0).toIso8601String(),
          'type': 'PUNCH_OUT',
        },
        {
          'userId': 'EMP_103',
          'timestamp': DateTime(2026, 10, 2, 9, 0).toIso8601String(),
          'type': 'PUNCH_IN',
        },
        {
          'userId': 'EMP_103',
          'timestamp': DateTime(2026, 10, 2, 17, 0).toIso8601String(),
          'type': 'PUNCH_OUT',
        },
      ];

      final report = service.auditCompliance(
        roster: roster,
        logs: logs,
        policy: LaborCompliancePolicy.defaultPolicy(),
      );

      expect(report.totalViolations, 0);
      expect(report.totalWarnings, 0);
      expect(report.incidents, isEmpty);
      expect(report.complianceScorePercent, 100.0);
    });
  });
}
