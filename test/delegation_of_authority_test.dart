import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/delegation_of_authority.dart';
import 'package:mybiometric/services/delegation_of_authority_service.dart';

void main() {
  group('DelegationOfAuthorityService Tests', () {
    final now = DateTime(2026, 10, 5, 12, 0);
    final activeDelegation = AuthorityDelegationRecord(
      delegationId: 'del-001',
      enterpriseId: 'ent-1',
      departmentId: 'dept-eng',
      delegatorUserId: 'user-manager-1',
      delegatorName: 'Sarah Connor',
      delegateeUserId: 'user-lead-1',
      delegateeName: 'John Doe',
      scope: DelegationScope.regularizationApproval,
      effectiveFrom: DateTime(2026, 10, 1),
      effectiveUntil: DateTime(2026, 10, 10),
      reason: 'Annual Leave in Europe',
      status: DelegationStatus.active,
      createdAt: DateTime(2026, 9, 28),
    );

    test('Validates delegation creation parameters', () {
      expect(
        DelegationOfAuthorityService.validateDelegation(
          delegatorUserId: 'user-1',
          delegateeUserId: 'user-1', // same user
          effectiveFrom: DateTime(2026, 10, 1),
          effectiveUntil: DateTime(2026, 10, 5),
        ),
        contains('Cannot delegate authority to oneself'),
      );

      expect(
        DelegationOfAuthorityService.validateDelegation(
          delegatorUserId: 'user-1',
          delegateeUserId: 'user-2',
          effectiveFrom: DateTime(2026, 10, 10),
          effectiveUntil: DateTime(2026, 10, 5), // end before start
        ),
        contains('Effective end date must be strictly after start date'),
      );

      expect(
        DelegationOfAuthorityService.validateDelegation(
          delegatorUserId: 'user-1',
          delegateeUserId: 'user-2',
          effectiveFrom: DateTime(2026, 10, 1),
          effectiveUntil: DateTime(2026, 10, 10),
        ),
        isNull,
      );
    });

    test('Confirms acting authority during active window for assigned scope', () {
      final hasAuth = DelegationOfAuthorityService.hasActingAuthority(
        delegations: [activeDelegation],
        userId: 'user-lead-1',
        departmentId: 'dept-eng',
        requiredScope: DelegationScope.regularizationApproval,
        atTime: now,
      );
      expect(hasAuth, isTrue);
    });

    test('Rejects acting authority for ungranted scope or expired date', () {
      // Trying to approve leave when only regularization was delegated
      final canApproveLeave = DelegationOfAuthorityService.hasActingAuthority(
        delegations: [activeDelegation],
        userId: 'user-lead-1',
        departmentId: 'dept-eng',
        requiredScope: DelegationScope.leaveApproval,
        atTime: now,
      );
      expect(canApproveLeave, isFalse);

      // Checking after expiration date
      final afterExpiry = DelegationOfAuthorityService.hasActingAuthority(
        delegations: [activeDelegation],
        userId: 'user-lead-1',
        departmentId: 'dept-eng',
        requiredScope: DelegationScope.regularizationApproval,
        atTime: DateTime(2026, 10, 15),
      );
      expect(afterExpiry, isFalse);
    });

    test('Serializes and deserializes AuthorityDelegationRecord cleanly', () {
      final map = activeDelegation.toMap();
      final revived = AuthorityDelegationRecord.fromMap(map);
      expect(revived.delegationId, equals(activeDelegation.delegationId));
      expect(revived.delegatorName, equals(activeDelegation.delegatorName));
      expect(revived.delegateeName, equals(activeDelegation.delegateeName));
      expect(revived.scope, equals(activeDelegation.scope));
      expect(revived.status, equals(activeDelegation.status));
    });
  });
}
