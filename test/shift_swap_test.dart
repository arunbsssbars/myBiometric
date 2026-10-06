import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/shift_swap_request.dart';
import 'package:mybiometric/services/shift_swap_service.dart';

void main() {
  group('Enterprise Shift Swapping & Peer Coverage Suite', () {
    test('ShiftSwapRequest serializes and deserializes accurately with default states', () {
      final now = DateTime(2026, 10, 1, 10, 0);
      final reqDate = DateTime(2026, 10, 5);
      final targetDate = DateTime(2026, 10, 6);

      final request = ShiftSwapRequest(
        id: 'swap-123',
        enterpriseId: 'ent-999',
        requesterId: 'emp-1',
        requesterName: 'Alice Smith',
        requesterDepartment: 'Logistics',
        requesterShiftName: 'Morning Shift',
        requesterDate: reqDate,
        targetEmployeeId: 'emp-2',
        targetEmployeeName: 'Bob Builder',
        targetDepartment: 'Logistics',
        targetShiftName: 'Evening Shift',
        targetDate: targetDate,
        reason: 'Family appointment on Monday',
        status: ShiftSwapStatus.pendingPeer,
        createdAt: now,
      );

      expect(request.isPendingPeer, isTrue);
      expect(request.isPendingManager, isFalse);
      expect(request.isApproved, isFalse);
      expect(request.isFinalized, isFalse);
      expect(request.statusDisplay, 'Awaiting Peer Approval');

      final map = request.toMap();
      final parsed = ShiftSwapRequest.fromMap(map, id: 'swap-123');

      expect(parsed.id, 'swap-123');
      expect(parsed.enterpriseId, 'ent-999');
      expect(parsed.requesterName, 'Alice Smith');
      expect(parsed.targetEmployeeName, 'Bob Builder');
      expect(parsed.status, ShiftSwapStatus.pendingPeer);
      expect(parsed.reason, 'Family appointment on Monday');
    });

    test('ShiftSwapRequest copyWith updates lifecycle status cleanly', () {
      final now = DateTime(2026, 10, 1, 10, 0);
      final request = ShiftSwapRequest(
        id: 'swap-456',
        enterpriseId: 'ent-999',
        requesterId: 'emp-1',
        requesterName: 'Alice Smith',
        requesterDate: DateTime(2026, 10, 5),
        targetEmployeeId: 'emp-2',
        targetEmployeeName: 'Bob Builder',
        targetDate: DateTime(2026, 10, 6),
        reason: 'Doctor appointment',
        createdAt: now,
      );

      final peerAccepted = request.copyWith(
        status: ShiftSwapStatus.pendingManager,
        peerRespondedAt: now.add(const Duration(hours: 1)),
      );

      expect(peerAccepted.isPendingPeer, isFalse);
      expect(peerAccepted.isPendingManager, isTrue);
      expect(peerAccepted.statusDisplay, 'Awaiting Manager Review');

      final managerApproved = peerAccepted.copyWith(
        status: ShiftSwapStatus.approved,
        managerRespondedAt: now.add(const Duration(hours: 2)),
        managerUid: 'mgr-001',
      );

      expect(managerApproved.isPendingManager, isFalse);
      expect(managerApproved.isApproved, isTrue);
      expect(managerApproved.isFinalized, isTrue);
      expect(managerApproved.statusDisplay, 'Approved & Confirmed');
    });

    test('ShiftSwapService.validateSwapEligibility enforces business constraints', () {
      final now = DateTime(2026, 10, 1, 10, 0);

      // Error 1: Same user swap
      final selfSwapError = ShiftSwapService.validateSwapEligibility(
        requesterDate: DateTime(2026, 10, 5),
        targetDate: DateTime(2026, 10, 6),
        requesterId: 'emp-1',
        targetId: 'emp-1',
        now: now,
      );
      expect(selfSwapError, contains('Cannot initiate a shift swap with yourself'));

      // Error 2: Past date
      final pastDateError = ShiftSwapService.validateSwapEligibility(
        requesterDate: DateTime(2026, 9, 28),
        targetDate: DateTime(2026, 10, 5),
        requesterId: 'emp-1',
        targetId: 'emp-2',
        now: now,
      );
      expect(pastDateError, contains('cannot be in the past'));

      // Valid: Future dates & distinct employees
      final validCheck = ShiftSwapService.validateSwapEligibility(
        requesterDate: DateTime(2026, 10, 5),
        targetDate: DateTime(2026, 10, 6),
        requesterId: 'emp-1',
        targetId: 'emp-2',
        now: now,
      );
      expect(validCheck, isNull);
    });
  });
}
