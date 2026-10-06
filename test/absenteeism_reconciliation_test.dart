import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/leave_request.dart';
import 'package:mybiometric/services/absenteeism_reconciliation_service.dart';

void main() {
  group('Absenteeism Reconciliation Suite', () {
    final staffList = [
      {'id': 'u1', 'employeeId': 'EMP1', 'fullName': 'Alice Johnson'},
      {'id': 'u2', 'employeeId': 'EMP2', 'fullName': 'Bob Smith'},
      {'id': 'u3', 'employeeId': 'EMP3', 'fullName': 'Carol Danvers'},
      {'id': 'u4', 'employeeId': 'EMP4', 'fullName': 'David Miller'},
    ];

    final targetDate = DateTime(2026, 10, 2);

    final attendanceLogs = [
      {
        'employeeId': 'EMP1',
        'userId': 'u1',
        'timestamp': DateTime(2026, 10, 2, 9, 5),
        'punchStatus': 'ON_TIME',
      },
      {
        'employeeId': 'EMP2',
        'userId': 'u2',
        'timestamp': DateTime(2026, 10, 2, 9, 45),
        'punchStatus': 'LATE_ARRIVAL',
      },
    ];

    final approvedLeaves = [
      LeaveRequest(
        id: 'leave_3',
        userId: 'u3',
        enterpriseId: 'ent_corp',
        employeeId: 'EMP3',
        employeeName: 'Carol Danvers',
        leaveType: 'PAID',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 5),
        daysCount: 5,
        reason: 'Family vacation',
        status: 'APPROVED',
        appliedAt: DateTime(2026, 9, 25),
      ),
    ];

    test('evaluateAttendanceData accurately calculates present, late, on leave, and absent counts', () {
      final report = AbsenteeismReconciliationService.evaluateAttendanceData(
        staffList: staffList,
        attendanceLogs: attendanceLogs,
        approvedLeaves: approvedLeaves,
        targetDate: targetDate,
      );

      expect(report.totalStaff, equals(4));
      expect(report.presentCount, equals(2)); // Alice & Bob
      expect(report.lateCount, equals(1)); // Bob
      expect(report.onLeaveCount, equals(1)); // Carol
      expect(report.absentCount, equals(1)); // David
      expect(report.attendanceRate, equals(50.0)); // 2 of 4
      expect(report.absentEmployees.first['employeeId'], equals('EMP4'));
    });
  });
}
