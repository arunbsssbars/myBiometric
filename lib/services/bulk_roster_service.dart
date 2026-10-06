import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/bulk_roster_import.dart';
import 'audit_log_service.dart';

/// Enterprise Bulk Employee Onboarding & CSV Import Service
class BulkRosterService {
  final FirebaseFirestore? _customFirestore;

  BulkRosterService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  static const List<String> validRoles = [
    'employee',
    'manager',
    'supervisor',
    'admin',
    'enterprise_admin',
  ];

  /// Generates a standardized CSV template string
  static String generateCsvTemplate() {
    return '''Full Name,Employee ID,Email,Role,Department,Branch ID,Assigned Shift
Alice Johnson,EMP001,alice@company.com,employee,Engineering,HQ,Morning Shift
Bob Smith,EMP002,bob@company.com,manager,Operations,HQ,General Shift
Carol Danvers,EMP003,carol@company.com,supervisor,Logistics,HQ,Evening Shift''';
  }

  /// Parses CSV text content into validated BulkImportRecords
  BulkImportResult parseCsvContent(
    String csvText, {
    Set<String>? existingEmployeeIds,
    Set<String>? existingEmails,
  }) {
    final cleanText = csvText.trim();
    if (cleanText.isEmpty) {
      return const BulkImportResult(
        totalRows: 0,
        validCount: 0,
        invalidCount: 0,
        records: [],
        generalErrors: ['CSV content is empty.'],
      );
    }

    final rawLines = cleanText.split(RegExp(r'\r?\n'));
    final List<String> lines = rawLines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.isEmpty) {
      return const BulkImportResult(
        totalRows: 0,
        validCount: 0,
        invalidCount: 0,
        records: [],
        generalErrors: ['No readable rows found in CSV.'],
      );
    }

    // Determine if first row is header
    int startIndex = 0;
    final firstRowLower = lines.first.toLowerCase();
    if (firstRowLower.contains('full name') ||
        firstRowLower.contains('name') ||
        firstRowLower.contains('employee id') ||
        firstRowLower.contains('id') ||
        firstRowLower.contains('email')) {
      startIndex = 1;
    }

    final List<BulkImportRecord> records = [];
    final Set<String> batchEmployeeIds = {};
    final Set<String> batchEmails = {};

    final existingIdsLower = existingEmployeeIds?.map((e) => e.trim().toLowerCase()).toSet() ?? {};
    final existingEmailsLower = existingEmails?.map((e) => e.trim().toLowerCase()).toSet() ?? {};

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i];
      final rowNum = i + 1;
      final cols = _parseCsvLine(line);

      final fullName = cols.isNotEmpty ? cols[0].trim() : '';
      final employeeId = cols.length > 1 ? cols[1].trim() : '';
      final email = cols.length > 2 ? cols[2].trim().toLowerCase() : '';
      final rawRole = cols.length > 3 ? cols[3].trim().toLowerCase() : 'employee';
      final department = cols.length > 4 && cols[4].trim().isNotEmpty ? cols[4].trim() : 'General';
      final branchId = cols.length > 5 && cols[5].trim().isNotEmpty ? cols[5].trim() : 'HQ';
      final assignedShift = cols.length > 6 && cols[6].trim().isNotEmpty ? cols[6].trim() : 'Standard Shift';

      final List<String> errors = [];

      // 1. Full Name validation
      if (fullName.isEmpty) {
        errors.add('Full Name is required.');
      } else if (fullName.length < 2) {
        errors.add('Full Name must be at least 2 characters.');
      }

      // 2. Employee ID validation
      if (employeeId.isEmpty) {
        errors.add('Employee ID is required.');
      } else {
        final idKey = employeeId.toLowerCase();
        if (batchEmployeeIds.contains(idKey)) {
          errors.add("Duplicate Employee ID '$employeeId' within CSV batch.");
        } else if (existingIdsLower.contains(idKey)) {
          errors.add("Employee ID '$employeeId' already exists in organization roster.");
        } else {
          batchEmployeeIds.add(idKey);
        }
      }

      // 3. Email validation
      if (email.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false);
        if (!emailRegex.hasMatch(email)) {
          errors.add("Invalid email format '$email'.");
        } else if (batchEmails.contains(email)) {
          errors.add("Duplicate email '$email' within CSV batch.");
        } else if (existingEmailsLower.contains(email)) {
          errors.add("Email '$email' is already registered.");
        } else {
          batchEmails.add(email);
        }
      }

      // 4. Role validation
      String role = 'employee';
      if (rawRole.isNotEmpty) {
        if (validRoles.contains(rawRole)) {
          role = rawRole;
        } else {
          role = 'employee'; // Fallback safely
        }
      }

      records.add(BulkImportRecord(
        rowNumber: rowNum,
        fullName: fullName,
        employeeId: employeeId,
        email: email,
        role: role,
        department: department,
        branchId: branchId,
        assignedShift: assignedShift,
        isValid: errors.isEmpty,
        errors: errors,
      ));
    }

    final validCount = records.where((r) => r.isValid).length;
    final invalidCount = records.where((r) => !r.isValid).length;

    return BulkImportResult(
      totalRows: records.length,
      validCount: validCount,
      invalidCount: invalidCount,
      records: records,
    );
  }

  /// Executes batch writing of valid records to Firestore in chunked transactions
  Future<int> executeBatchImport(
    String enterpriseId,
    List<BulkImportRecord> validRecords,
  ) async {
    if (validRecords.isEmpty) return 0;

    int totalImported = 0;
    const int chunkSize = 200; // 200 records * 2 doc writes = 400 operations (limit 500)

    for (int i = 0; i < validRecords.length; i += chunkSize) {
      final end = (i + chunkSize < validRecords.length) ? i + chunkSize : validRecords.length;
      final chunk = validRecords.sublist(i, end);

      final batch = _firestore.batch();

      for (final record in chunk) {
        final docRef = _firestore
            .collection('enterprises')
            .doc(enterpriseId.trim())
            .collection('employees')
            .doc();

        final data = record.toFirestoreMap(enterpriseId: enterpriseId);
        batch.set(docRef, data);

        // Also write to users collection with docId matching employeeDocId
        final userDocRef = _firestore.collection('users').doc(docRef.id);
        batch.set(userDocRef, {
          ...data,
          'uid': docRef.id,
        });

        totalImported++;
      }

      await batch.commit();
    }

    // Log audit entry
    try {
      await AuditLogService().logAction(
        enterpriseId: enterpriseId,
        action: 'STAFF_BULK_IMPORTED',
        details: 'Successfully imported $totalImported employee records via batch CSV onboarding.',
        category: AuditLogService.categoryStaff,
      );
    } catch (_) {}

    return totalImported;
  }

  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }
}
