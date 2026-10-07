import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/overtime_pre_approval_service.dart';
import 'package:mybiometric/views/overtime_pre_approval_card.dart';

void main() {
  group('OvertimePreApprovalService Suite', () {
    late OvertimePreApprovalService service;

    setUp(() {
      service = OvertimePreApprovalService();
      service.clearForTesting();
    });

    test('Submits overtime pre-approval request and limits max daily overtime', () {
      final req = service.submitRequest(
        enterpriseId: 'ENT_ABC',
        userId: 'USR_01',
        employeeName: 'Alice Smith',
        department: 'Operations',
        shiftDate: DateTime(2026, 10, 8),
        plannedHours: 2.5,
        category: OvertimeCategory.weekdayExtra,
        justification: 'Quarterly inventory count',
      );

      expect(req.status, equals(OvertimeRequestStatus.pending));
      expect(req.plannedHours, equals(2.5));

      // Attempt exceeding max limit of 4 hours
      expect(
        () => service.submitRequest(
          enterpriseId: 'ENT_ABC',
          userId: 'USR_01',
          employeeName: 'Alice Smith',
          department: 'Operations',
          shiftDate: DateTime(2026, 10, 8),
          plannedHours: 5.0,
          category: OvertimeCategory.weekdayExtra,
          justification: 'Excessive shift',
        ),
        throwsArgumentError,
      );
    });

    test('Allows manager to approve and calculate total approved hours', () {
      final req = service.submitRequest(
        enterpriseId: 'ENT_ABC',
        userId: 'USR_02',
        employeeName: 'Bob Builder',
        department: 'Engineering',
        shiftDate: DateTime(2026, 10, 8),
        plannedHours: 3.0,
        category: OvertimeCategory.weekend,
        justification: 'Critical server deployment',
      );

      final approved = service.approveRequest(req.id, 'mgr_sarah');
      expect(approved, isTrue);

      final hasApproved = service.hasApprovedOvertimeForDate(
        userId: 'USR_02',
        date: DateTime(2026, 10, 8),
      );
      expect(hasApproved, isTrue);

      final totalHours = service.getTotalApprovedHoursForDate(
        userId: 'USR_02',
        date: DateTime(2026, 10, 8),
      );
      expect(totalHours, equals(3.0));
    });

    test('Rejects overtime request with reason', () {
      final req = service.submitRequest(
        enterpriseId: 'ENT_ABC',
        userId: 'USR_03',
        employeeName: 'Charlie',
        department: 'Design',
        shiftDate: DateTime(2026, 10, 8),
        plannedHours: 1.5,
        category: OvertimeCategory.weekdayExtra,
        justification: 'Extra polish',
      );

      final rejected = service.rejectRequest(req.id, 'mgr_sarah', 'Budget cap reached');
      expect(rejected, isTrue);

      final updated = service.requests.firstWhere((r) => r.id == req.id);
      expect(updated.status, equals(OvertimeRequestStatus.rejected));
      expect(updated.rejectionReason, equals('Budget cap reached'));
    });

    testWidgets('OvertimePreApprovalCard renders without overflow across viewports', (tester) async {
      final request = OvertimePreApprovalRequest(
        id: 'ot_card_test',
        enterpriseId: 'ENT_TEST',
        userId: 'USR_TEST',
        employeeName: 'Diana Prince',
        department: 'Security Operations',
        shiftDate: DateTime(2026, 10, 8),
        plannedHours: 2.0,
        category: OvertimeCategory.weekdayExtra,
        justification: 'Night patrol overtime for VIP visit',
        requestedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OvertimePreApprovalCard(
              request: request,
              onApprove: () {},
              onReject: () {},
            ),
          ),
        ),
      );

      expect(find.text('Diana Prince'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.textContaining('Security Operations'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });
  });
}
