/// Standard enterprise payroll interchange formats
enum PayrollExportFormat {
  sapCat2,
  adpCsv,
  workdayXml,
  tallyXml,
  standardCsv,
}

/// Configuration specifying the enterprise export profile
class PayrollExportConfig {
  final String enterpriseId;
  final String companyCode; // e.g. "1000" for SAP or "ADP-CORP"
  final PayrollExportFormat format;
  final String delimiter; // e.g. "," or ";" or "\t"
  final bool includeOvertimeBreakdown;
  final bool includeAbsenceDeductions;
  final String batchPrefix;

  const PayrollExportConfig({
    required this.enterpriseId,
    required this.companyCode,
    this.format = PayrollExportFormat.sapCat2,
    this.delimiter = ',',
    this.includeOvertimeBreakdown = true,
    this.includeAbsenceDeductions = true,
    this.batchPrefix = 'BATCH',
  });

  Map<String, dynamic> toMap() => {
    'enterpriseId': enterpriseId,
    'companyCode': companyCode,
    'format': format.name,
    'delimiter': delimiter,
    'includeOvertimeBreakdown': includeOvertimeBreakdown,
    'includeAbsenceDeductions': includeAbsenceDeductions,
    'batchPrefix': batchPrefix,
  };

  factory PayrollExportConfig.fromMap(Map<String, dynamic> map) {
    return PayrollExportConfig(
      enterpriseId: map['enterpriseId'] as String? ?? '',
      companyCode: map['companyCode'] as String? ?? '1000',
      format: PayrollExportFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => PayrollExportFormat.sapCat2,
      ),
      delimiter: map['delimiter'] as String? ?? ',',
      includeOvertimeBreakdown: map['includeOvertimeBreakdown'] as bool? ?? true,
      includeAbsenceDeductions: map['includeAbsenceDeductions'] as bool? ?? true,
      batchPrefix: map['batchPrefix'] as String? ?? 'BATCH',
    );
  }
}

/// A line item of employee attendance ready for payroll export
class PayrollTimeEntry {
  final String employeeId;
  final String employeeName;
  final DateTime date;
  final double regularHours;
  final double overtimeHours;
  final String costCenter;
  final String attendanceCode; // 'REG', 'OT', 'ABS', 'HOL'

  const PayrollTimeEntry({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.regularHours,
    this.overtimeHours = 0.0,
    this.costCenter = 'CC-100',
    this.attendanceCode = 'REG',
  });
}

/// Summary result of the generated export batch
class PayrollExportResult {
  final String batchId;
  final PayrollExportFormat format;
  final int totalRecords;
  final double totalRegularHours;
  final double totalOvertimeHours;
  final String fileName;
  final String fileContent;

  const PayrollExportResult({
    required this.batchId,
    required this.format,
    required this.totalRecords,
    required this.totalRegularHours,
    required this.totalOvertimeHours,
    required this.fileName,
    required this.fileContent,
  });
}
