import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/timesheet_export_template.dart';
import 'package:mybiometric_app/services/payroll_export_service.dart';
import 'package:mybiometric_app/services/timesheet_custom_export_service.dart';

void main() {
  group('TimesheetCustomExportService Tests', () {
    test('Exports custom CSV with selected columns according to template', () {
      final summary = PayrollEmployeeSummary(
        userId: 'u1',
        employeeId: 'EMP-001',
        fullName: 'Grace Hopper',
        department: 'Engineering',
      )
        ..daysPresent = 20
        ..totalWorkMinutes = 9600 // 160 hrs
        ..totalOvertimeMinutes = 600; // 10 hrs

      const template = TimesheetExportTemplate(
        id: 'tmpl_std',
        name: 'Standard Payroll',
        visibleColumns: [
          TimesheetColumnField.employeeId,
          TimesheetColumnField.fullName,
          TimesheetColumnField.netPayableHours,
          TimesheetColumnField.overtimeHours,
        ],
        delimiter: ',',
      );

      final exported = TimesheetCustomExportService.exportWithTemplate(
        summaries: [summary],
        template: template,
      );

      expect(exported, contains('Employee ID,Full Name,Net Payable Hours,Overtime Hours'));
      expect(exported, contains('"EMP-001","Grace Hopper",160.00,10.00'));
    });
  });
}
