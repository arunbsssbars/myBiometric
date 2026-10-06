import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/multi_format_payroll_export.dart';
import 'package:mybiometric/services/multi_format_payroll_export_service.dart';

void main() {
  group('MultiFormatPayrollExportService Tests', () {
    final entries = [
      PayrollTimeEntry(
        employeeId: 'EMP-001',
        employeeName: 'John Doe',
        date: DateTime(2026, 10, 5),
        regularHours: 8.0,
        overtimeHours: 2.0,
        costCenter: 'CC-ENG',
      ),
      PayrollTimeEntry(
        employeeId: 'EMP-002',
        employeeName: 'Jane Smith',
        date: DateTime(2026, 10, 5),
        regularHours: 8.0,
        overtimeHours: 0.0,
        costCenter: 'CC-HR',
      ),
    ];

    test('Generates valid SAP CAT2 format text file', () {
      const config = PayrollExportConfig(
        enterpriseId: 'ent-1',
        companyCode: '1000',
        format: PayrollExportFormat.sapCat2,
      );

      final res = MultiFormatPayrollExportService.generateExport(
        config: config,
        entries: entries,
        exportDate: DateTime(2026, 10, 5),
      );

      expect(res.fileName, startsWith('SAP_CAT2_'));
      expect(res.totalRecords, equals(2));
      expect(res.totalRegularHours, equals(16.0));
      expect(res.totalOvertimeHours, equals(2.0));
      expect(res.fileContent, contains('H1000CAT2BATCH'));
      expect(res.fileContent, contains('D|EMP-001|20261005|REG|8.00|CC-ENG'));
      expect(res.fileContent, contains('D|EMP-001|20261005|OT_1.5|2.00|CC-ENG'));
    });

    test('Generates valid ADP eTime CSV file', () {
      const config = PayrollExportConfig(
        enterpriseId: 'ent-1',
        companyCode: 'ADP-01',
        format: PayrollExportFormat.adpCsv,
      );

      final res = MultiFormatPayrollExportService.generateExport(
        config: config,
        entries: entries,
        exportDate: DateTime(2026, 10, 5),
      );

      expect(res.fileName, startsWith('ADP_eTime_'));
      expect(res.fileContent, contains('CoCode,BatchID,File#,Date,RegHours,OTHours,CostCenter'));
      expect(res.fileContent, contains('ADP-01,'));
      expect(res.fileContent, contains('EMP-001'));
    });

    test('Generates valid Workday XML file', () {
      const config = PayrollExportConfig(
        enterpriseId: 'ent-1',
        companyCode: '1000',
        format: PayrollExportFormat.workdayXml,
      );

      final res = MultiFormatPayrollExportService.generateExport(
        config: config,
        entries: entries,
        exportDate: DateTime(2026, 10, 5),
      );

      expect(res.fileName, startsWith('Workday_Time_'));
      expect(res.fileContent, contains('<wd:Time_Tracking_Data'));
      expect(res.fileContent, contains('<wd:Employee_ID>EMP-001</wd:Employee_ID>'));
      expect(res.fileContent, contains('<wd:Regular_Hours>8.0</wd:Regular_Hours>'));
    });

    test('Generates valid Tally ERP XML file', () {
      const config = PayrollExportConfig(
        enterpriseId: 'ent-1',
        companyCode: '1000',
        format: PayrollExportFormat.tallyXml,
      );

      final res = MultiFormatPayrollExportService.generateExport(
        config: config,
        entries: entries,
        exportDate: DateTime(2026, 10, 5),
      );

      expect(res.fileName, startsWith('Tally_Attendance_'));
      expect(res.fileContent, contains('<ENVELOPE>'));
      expect(res.fileContent, contains('<EMPLOYEENAME>John Doe</EMPLOYEENAME>'));
      expect(res.fileContent, contains('<TOTALHOURS>10.0</TOTALHOURS>'));
    });

    test('Serializes and deserializes PayrollExportConfig cleanly', () {
      const config = PayrollExportConfig(
        enterpriseId: 'ent-1',
        companyCode: '9999',
        format: PayrollExportFormat.workdayXml,
        delimiter: ';',
      );

      final map = config.toMap();
      final revived = PayrollExportConfig.fromMap(map);

      expect(revived.enterpriseId, equals(config.enterpriseId));
      expect(revived.companyCode, equals('9999'));
      expect(revived.format, equals(PayrollExportFormat.workdayXml));
    });
  });
}
