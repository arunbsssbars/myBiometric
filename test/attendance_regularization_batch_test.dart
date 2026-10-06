import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/attendance_regularization_request.dart';
import 'package:mybiometric/services/attendance_regularization_batch_service.dart';

void main() {
  group('AttendanceRegularizationBatchService Tests', () {
    final req1 = AttendanceRegularizationRequest(
      id: 'req_01',
      enterpriseId: 'ent_demo',
      userId: 'usr-1',
      employeeName: 'Alice',
      employeeId: 'EMP-01',
      targetDate: DateTime(2026, 10, 1),
      category: RegularizationCategory.forgotPunch,
      requestedCheckIn: DateTime(2026, 10, 1, 9, 0),
      requestedCheckOut: DateTime(2026, 10, 1, 17, 0),
      reasonDescription: 'Biometric kiosk offline',
      status: RegularizationStatus.pending,
      appliedAt: DateTime(2026, 10, 1),
    );

    final req2 = AttendanceRegularizationRequest(
      id: 'req_02',
      enterpriseId: 'ent_demo',
      userId: 'usr-2',
      employeeName: 'Bob',
      employeeId: 'EMP-02',
      targetDate: DateTime(2026, 10, 1),
      category: RegularizationCategory.clientVisit,
      requestedCheckIn: DateTime(2026, 10, 1, 9, 30),
      requestedCheckOut: DateTime(2026, 10, 1, 18, 0),
      reasonDescription: 'Client meeting onsite',
      status: RegularizationStatus.pending,
      appliedAt: DateTime(2026, 10, 1),
    );

    test('Bulk approves pending requests accurately', () {
      final result = AttendanceRegularizationBatchService.processBatch(
        requests: [req1, req2],
        targetStatus: RegularizationStatus.approved,
        reviewerUid: 'admin_1',
        reviewerName: 'Admin Chief',
      );

      expect(result.totalProcessed, equals(2));
      expect(result.approvedCount, equals(2));
      expect(result.rejectedCount, equals(0));
      expect(result.modifiedRequestIds, containsAll(['req_01', 'req_02']));
    });
  });
}
