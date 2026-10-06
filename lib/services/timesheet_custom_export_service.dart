import '../domain/models/timesheet_export_template.dart';
import 'payroll_export_service.dart';

/// Formats timesheet data into dynamic structured exports based on templates
class TimesheetCustomExportService {
  /// Generates delimited text (CSV/TSV) based on the specified template and summaries
  static String exportWithTemplate({
    required List<PayrollEmployeeSummary> summaries,
    required TimesheetExportTemplate template,
  }) {
    final buffer = StringBuffer();
    final d = template.delimiter;

    // Header
    if (template.includeHeaderRow) {
      final headerTitles = template.visibleColumns.map((c) {
        switch (c) {
          case TimesheetColumnField.employeeId:
            return 'Employee ID';
          case TimesheetColumnField.fullName:
            return 'Full Name';
          case TimesheetColumnField.department:
            return 'Department';
          case TimesheetColumnField.daysWorked:
            return 'Days Worked';
          case TimesheetColumnField.grossHours:
            return 'Gross Hours';
          case TimesheetColumnField.unpaidBreakHours:
            return 'Unpaid Break Hours';
          case TimesheetColumnField.netPayableHours:
            return 'Net Payable Hours';
          case TimesheetColumnField.overtimeHours:
            return 'Overtime Hours';
          case TimesheetColumnField.lateArrivalsCount:
            return 'Late Arrivals';
          case TimesheetColumnField.earlyDeparturesCount:
            return 'Early Departures';
        }
      }).join(d);
      buffer.writeln(headerTitles);
    }

    // Rows
    for (final s in summaries) {
      final rowValues = template.visibleColumns.map((c) {
        switch (c) {
          case TimesheetColumnField.employeeId:
            return '"${s.employeeId}"';
          case TimesheetColumnField.fullName:
            return '"${s.fullName}"';
          case TimesheetColumnField.department:
            return '"${s.department}"';
          case TimesheetColumnField.daysWorked:
            return '${s.daysPresent}';
          case TimesheetColumnField.grossHours:
            return s.grossHours.toStringAsFixed(2);
          case TimesheetColumnField.unpaidBreakHours:
            return s.unpaidBreakHours.toStringAsFixed(2);
          case TimesheetColumnField.netPayableHours:
            return s.payableHours.toStringAsFixed(2);
          case TimesheetColumnField.overtimeHours:
            return s.overtimeHours.toStringAsFixed(2);
          case TimesheetColumnField.lateArrivalsCount:
            return '${s.lateDaysCount}';
          case TimesheetColumnField.earlyDeparturesCount:
            return '${s.earlyDepartureCount}';
        }
      }).join(d);
      buffer.writeln(rowValues);
    }

    return buffer.toString();
  }
}
