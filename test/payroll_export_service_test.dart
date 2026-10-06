import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/payroll_export_service.dart';

void main() {
  group('PayrollExportService & PayrollEmployeeSummary Tests', () {
    test('Calculates basic payroll summaries from raw log maps', () {
      final staff = [
        {
          'id': 'u1',
          'fullName': 'Alice Smith',
          'employeeId': 'EMP-001',
          'department': 'Engineering',
        },
        {
          'id': 'u2',
          'fullName': 'Bob Jones',
          'employeeId': 'EMP-002',
          'department': 'Sales',
        },
      ];

      final logs = [
        {
          'userId': 'u1',
          'timestamp': DateTime(2026, 10, 1, 9, 0),
          'shiftDurationMinutes': 480,
          'overtimeMinutes': 30,
          'lateMinutes': 0,
          'earlyMinutes': 0,
          'workStatus': 'FULL_DAY',
        },
        {
          'userId': 'u1',
          'timestamp': DateTime(2026, 10, 2, 9, 0),
          'shiftDurationMinutes': 450,
          'overtimeMinutes': 0,
          'lateMinutes': 15,
          'earlyMinutes': 0,
          'workStatus': 'FULL_DAY',
          'punchStatus': 'LATE_ARRIVAL',
        },
        {
          'userId': 'u2',
          'timestamp': DateTime(2026, 10, 1, 9, 30),
          'shiftDurationMinutes': 240,
          'overtimeMinutes': 0,
          'lateMinutes': 0,
          'earlyMinutes': 60,
          'workStatus': 'HALF_DAY',
          'punchStatus': 'EARLY_DEPARTURE',
        },
      ];

      final summaries = PayrollExportService.generatePayrollSummaryFromMaps(
        logs: logs,
        staff: staff,
      );

      expect(summaries.length, equals(2));

      final alice = summaries.firstWhere((s) => s.userId == 'u1');
      expect(alice.fullName, equals('Alice Smith'));
      expect(alice.daysPresent, equals(2));
      expect(alice.fullDaysCount, equals(2));
      expect(alice.totalWorkMinutes, equals(930));
      expect(alice.totalOvertimeMinutes, equals(30));
      expect(alice.lateDaysCount, equals(1));
      expect(alice.grossHours, closeTo(15.5, 0.01));

      final bob = summaries.firstWhere((s) => s.userId == 'u2');
      expect(bob.fullName, equals('Bob Jones'));
      expect(bob.daysPresent, equals(1));
      expect(bob.halfDaysCount, equals(1));
      expect(bob.earlyDepartureCount, equals(1));
      expect(bob.totalWorkMinutes, equals(240));
      expect(bob.grossHours, closeTo(4.0, 0.01));
    });

    test('Generates detailed and standard CSV timesheets', () {
      final summary = PayrollEmployeeSummary(
        userId: 'u1',
        employeeId: 'EMP-100',
        fullName: 'Charlie Developer',
        department: 'DevOps',
        totalBreakMinutes: 60,
        unpaidBreakMinutes: 30,
        paidBreakMinutes: 30,
      )
        ..daysPresent = 5
        ..fullDaysCount = 5
        ..totalWorkMinutes = 2400
        ..totalOvertimeMinutes = 120
        ..lateDaysCount = 0
        ..earlyDepartureCount = 0;

      expect(summary.netWorkMinutes, equals(2370));
      expect(summary.payableHours, closeTo(39.5, 0.01));
      expect(summary.overtimeHours, closeTo(2.0, 0.01));

      final csvDetailed = PayrollExportService.generateDetailedPayrollCsv(
        [summary],
        periodTitle: 'October 2026',
      );
      expect(csvDetailed, contains('October 2026'));
      expect(csvDetailed, contains('Charlie Developer'));
      expect(csvDetailed, contains('EMP-100'));
      expect(csvDetailed, contains('DevOps'));
    });
  });
}
