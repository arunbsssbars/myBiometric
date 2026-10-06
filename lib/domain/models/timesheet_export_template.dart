/// Available exportable column fields for payroll and timesheet integration
enum TimesheetColumnField {
  employeeId,
  fullName,
  department,
  daysWorked,
  grossHours,
  unpaidBreakHours,
  netPayableHours,
  overtimeHours,
  lateArrivalsCount,
  earlyDeparturesCount,
}

/// Custom export template configuration
class TimesheetExportTemplate {
  final String id;
  final String name;
  final List<TimesheetColumnField> visibleColumns;
  final String delimiter; // e.g. ',' or ';' or '\t'
  final bool includeHeaderRow;

  const TimesheetExportTemplate({
    required this.id,
    required this.name,
    this.visibleColumns = const [
      TimesheetColumnField.employeeId,
      TimesheetColumnField.fullName,
      TimesheetColumnField.department,
      TimesheetColumnField.daysWorked,
      TimesheetColumnField.netPayableHours,
      TimesheetColumnField.overtimeHours,
    ],
    this.delimiter = ',',
    this.includeHeaderRow = true,
  });
}
