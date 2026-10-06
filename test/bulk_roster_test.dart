import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/bulk_roster_import.dart';
import 'package:mybiometric_app/services/bulk_roster_service.dart';

void main() {
  group('Enterprise Bulk Staff Onboarding Suite', () {
    test('generateCsvTemplate provides valid header and sample rows', () {
      final template = BulkRosterService.generateCsvTemplate();

      expect(template, contains('Full Name'));
      expect(template, contains('Employee ID'));
      expect(template, contains('Email'));
      expect(template, contains('Role'));
      expect(template, contains('Department'));
    });

    test('parseCsvContent parses valid rows into BulkImportRecords', () {
      final service = BulkRosterService();
      const csv = '''Full Name,Employee ID,Email,Role,Department,Branch ID,Assigned Shift
Alice Johnson,EMP001,alice@example.com,employee,Engineering,HQ,Morning Shift
Bob Smith,EMP002,bob@example.com,manager,Operations,HQ,General Shift''';

      final result = service.parseCsvContent(csv);

      expect(result.totalRows, 2);
      expect(result.validCount, 2);
      expect(result.invalidCount, 0);
      expect(result.canImport, isTrue);

      final r1 = result.records[0];
      expect(r1.fullName, 'Alice Johnson');
      expect(r1.employeeId, 'EMP001');
      expect(r1.email, 'alice@example.com');
      expect(r1.role, 'employee');
      expect(r1.department, 'Engineering');
      expect(r1.isValid, isTrue);

      final r2 = result.records[1];
      expect(r2.fullName, 'Bob Smith');
      expect(r2.employeeId, 'EMP002');
      expect(r2.role, 'manager');
      expect(r2.isValid, isTrue);
    });

    test('parseCsvContent catches missing names, duplicate IDs, and invalid emails', () {
      final service = BulkRosterService();
      const csv = '''Full Name,Employee ID,Email,Role,Department,Branch ID,Assigned Shift
,EMP001,alice@example.com,employee,Engineering,HQ,Morning Shift
Bob Smith,,bob@example.com,manager,Operations,HQ,General Shift
Carol Danvers,EMP003,invalid-email-string,employee,Logistics,HQ,Evening Shift
Dave Miller,EMP003,dave@example.com,employee,Finance,HQ,Standard Shift''';

      final result = service.parseCsvContent(csv);

      expect(result.totalRows, 4);
      expect(result.validCount, 0);
      expect(result.invalidCount, 4);

      // Row 1 error: Missing name
      expect(result.records[0].isValid, isFalse);
      expect(result.records[0].errors.first, contains('Full Name is required'));

      // Row 2 error: Missing ID
      expect(result.records[1].isValid, isFalse);
      expect(result.records[1].errors.first, contains('Employee ID is required'));

      // Row 3 error: Invalid email format
      expect(result.records[2].isValid, isFalse);
      expect(result.records[2].errors.first, contains('Invalid email format'));

      // Row 4 error: Duplicate ID within batch
      expect(result.records[3].isValid, isFalse);
      expect(result.records[3].errors.first, contains('Duplicate Employee ID'));
    });

    test('parseCsvContent detects conflicts with existing organization database records', () {
      final service = BulkRosterService();
      const csv = '''Full Name,Employee ID,Email,Role,Department,Branch ID,Assigned Shift
Eve Adams,EMP999,eve@company.com,employee,Design,HQ,Morning Shift''';

      final existingIds = {'emp999'};
      final existingEmails = {'other@company.com'};

      final result = service.parseCsvContent(
        csv,
        existingEmployeeIds: existingIds,
        existingEmails: existingEmails,
      );

      expect(result.validCount, 0);
      expect(result.invalidCount, 1);
      expect(result.records.first.errors.first, contains('already exists in organization roster'));
    });

    test('BulkImportRecord serializes properly into Firestore schema', () {
      const record = BulkImportRecord(
        rowNumber: 1,
        fullName: 'Frank Castle',
        employeeId: 'EMP505',
        email: 'frank@company.com',
        role: 'manager',
        department: 'Security',
        branchId: 'Branch-2',
        assignedShift: 'Night Shift',
      );

      final map = record.toFirestoreMap(enterpriseId: 'ent-001');

      expect(map['fullName'], 'Frank Castle');
      expect(map['employeeId'], 'EMP505');
      expect(map['email'], 'frank@company.com');
      expect(map['role'], 'manager');
      expect(map['department'], 'Security');
      expect(map['enterpriseId'], 'ent-001');
      expect(map['biometricsEnrolled'], isFalse);
    });
  });
}
