import '../domain/models/multi_format_payroll_export.dart';

/// Multi-Format Enterprise Payroll Export Engine
class MultiFormatPayrollExportService {
  /// Generates the formatted export payload according to the configured standard
  static PayrollExportResult generateExport({
    required PayrollExportConfig config,
    required List<PayrollTimeEntry> entries,
    DateTime? exportDate,
  }) {
    final now = exportDate ?? DateTime.now();
    final batchId = '${config.batchPrefix}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch % 10000}';

    double totalReg = 0.0;
    double totalOt = 0.0;
    for (final e in entries) {
      totalReg += e.regularHours;
      totalOt += e.overtimeHours;
    }

    final String fileName;
    final String content;

    switch (config.format) {
      case PayrollExportFormat.sapCat2:
        fileName = 'SAP_CAT2_$batchId.txt';
        content = _formatSapCat2(config, entries);
        break;
      case PayrollExportFormat.adpCsv:
        fileName = 'ADP_eTime_$batchId.csv';
        content = _formatAdpCsv(config, batchId, entries);
        break;
      case PayrollExportFormat.workdayXml:
        fileName = 'Workday_Time_$batchId.xml';
        content = _formatWorkdayXml(config, batchId, entries);
        break;
      case PayrollExportFormat.tallyXml:
        fileName = 'Tally_Attendance_$batchId.xml';
        content = _formatTallyXml(config, batchId, entries);
        break;
      case PayrollExportFormat.standardCsv:
        fileName = 'Timesheet_$batchId.csv';
        content = _formatStandardCsv(config, entries);
        break;
    }

    return PayrollExportResult(
      batchId: batchId,
      format: config.format,
      totalRecords: entries.length,
      totalRegularHours: totalReg,
      totalOvertimeHours: totalOt,
      fileName: fileName,
      fileContent: content,
    );
  }

  static String _formatSapCat2(PayrollExportConfig config, List<PayrollTimeEntry> entries) {
    final buffer = StringBuffer();
    // SAP CAT2 header line
    buffer.writeln('H${config.companyCode}CAT2BATCH');

    for (final e in entries) {
      final ymd = '${e.date.year}${e.date.month.toString().padLeft(2, '0')}${e.date.day.toString().padLeft(2, '0')}';
      // RecordType(D) | Personnel# | Date | AttendanceType | Hours | CostCenter
      buffer.writeln('D|${e.employeeId}|$ymd|${e.attendanceCode}|${e.regularHours.toStringAsFixed(2)}|${e.costCenter}');
      if (config.includeOvertimeBreakdown && e.overtimeHours > 0) {
        buffer.writeln('D|${e.employeeId}|$ymd|OT_1.5|${e.overtimeHours.toStringAsFixed(2)}|${e.costCenter}');
      }
    }
    return buffer.toString();
  }

  static String _formatAdpCsv(PayrollExportConfig config, String batchId, List<PayrollTimeEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('CoCode,BatchID,File#,Date,RegHours,OTHours,CostCenter');
    for (final e in entries) {
      final ymd = '${e.date.month}/${e.date.day}/${e.date.year}';
      buffer.writeln(
        '${config.companyCode},$batchId,${e.employeeId},$ymd,${e.regularHours.toStringAsFixed(2)},${e.overtimeHours.toStringAsFixed(2)},${e.costCenter}',
      );
    }
    return buffer.toString();
  }

  static String _formatWorkdayXml(PayrollExportConfig config, String batchId, List<PayrollTimeEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<wd:Time_Tracking_Data xmlns:wd="urn:com.workday/bsvc" wd:Batch_ID="$batchId">');
    for (final e in entries) {
      final ymd = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      buffer.writeln('  <wd:Time_Entry>');
      buffer.writeln('    <wd:Employee_ID>${e.employeeId}</wd:Employee_ID>');
      buffer.writeln('    <wd:Date>$ymd</wd:Date>');
      buffer.writeln('    <wd:Regular_Hours>${e.regularHours}</wd:Regular_Hours>');
      buffer.writeln('    <wd:Overtime_Hours>${e.overtimeHours}</wd:Overtime_Hours>');
      buffer.writeln('    <wd:Cost_Center>${e.costCenter}</wd:Cost_Center>');
      buffer.writeln('  </wd:Time_Entry>');
    }
    buffer.writeln('</wd:Time_Tracking_Data>');
    return buffer.toString();
  }

  static String _formatTallyXml(PayrollExportConfig config, String batchId, List<PayrollTimeEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER><TALLYREQUEST>Import Data</TALLYREQUEST></HEADER>');
    buffer.writeln('  <BODY><DATA><TALLYMESSAGE>');
    for (final e in entries) {
      final ymd = '${e.date.year}${e.date.month.toString().padLeft(2, '0')}${e.date.day.toString().padLeft(2, '0')}';
      buffer.writeln('    <ATTENDANCE>');
      buffer.writeln('      <EMPLOYEENAME>${e.employeeName}</EMPLOYEENAME>');
      buffer.writeln('      <DATE>$ymd</DATE>');
      buffer.writeln('      <ATTENDANCETYPE>Present</ATTENDANCETYPE>');
      buffer.writeln('      <TOTALHOURS>${e.regularHours + e.overtimeHours}</TOTALHOURS>');
      buffer.writeln('    </ATTENDANCE>');
    }
    buffer.writeln('  </TALLYMESSAGE></DATA></BODY>');
    buffer.writeln('</ENVELOPE>');
    return buffer.toString();
  }

  static String _formatStandardCsv(PayrollExportConfig config, List<PayrollTimeEntry> entries) {
    final d = config.delimiter;
    final buffer = StringBuffer();
    buffer.writeln('EmployeeId${d}EmployeeName${d}Date${d}RegularHours${d}OvertimeHours${d}CostCenter');
    for (final e in entries) {
      final dateStr = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        '${e.employeeId}$d${e.employeeName}$d$dateStr$d${e.regularHours}$d${e.overtimeHours}$d${e.costCenter}',
      );
    }
    return buffer.toString();
  }
}
