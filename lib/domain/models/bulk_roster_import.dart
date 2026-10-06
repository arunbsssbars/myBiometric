import 'package:flutter/foundation.dart';

@immutable
class BulkImportRecord {
  final int rowNumber;
  final String fullName;
  final String employeeId;
  final String email;
  final String role;
  final String department;
  final String branchId;
  final String assignedShift;
  final bool isValid;
  final List<String> errors;

  const BulkImportRecord({
    required this.rowNumber,
    required this.fullName,
    required this.employeeId,
    this.email = '',
    this.role = 'employee',
    this.department = 'General',
    this.branchId = 'HQ',
    this.assignedShift = 'Standard Shift',
    this.isValid = true,
    this.errors = const [],
  });

  Map<String, dynamic> toFirestoreMap({required String enterpriseId}) {
    return {
      'fullName': fullName.trim(),
      'name': fullName.trim(),
      'employeeId': employeeId.trim(),
      'email': email.trim().toLowerCase(),
      'role': role.trim().toLowerCase(),
      'department': department.trim(),
      'branchId': branchId.trim(),
      'assignedShift': assignedShift.trim(),
      'enterpriseId': enterpriseId,
      'biometricsEnrolled': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  BulkImportRecord copyWith({
    int? rowNumber,
    String? fullName,
    String? employeeId,
    String? email,
    String? role,
    String? department,
    String? branchId,
    String? assignedShift,
    bool? isValid,
    List<String>? errors,
  }) {
    return BulkImportRecord(
      rowNumber: rowNumber ?? this.rowNumber,
      fullName: fullName ?? this.fullName,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      branchId: branchId ?? this.branchId,
      assignedShift: assignedShift ?? this.assignedShift,
      isValid: isValid ?? this.isValid,
      errors: errors ?? this.errors,
    );
  }
}

class BulkImportResult {
  final int totalRows;
  final int validCount;
  final int invalidCount;
  final List<BulkImportRecord> records;
  final List<String> generalErrors;

  const BulkImportResult({
    required this.totalRows,
    required this.validCount,
    required this.invalidCount,
    required this.records,
    this.generalErrors = const [],
  });

  bool get hasErrors => invalidCount > 0 || generalErrors.isNotEmpty;
  bool get canImport => validCount > 0;
  List<BulkImportRecord> get validRecords => records.where((r) => r.isValid).toList();
  List<BulkImportRecord> get invalidRecords => records.where((r) => !r.isValid).toList();
}
