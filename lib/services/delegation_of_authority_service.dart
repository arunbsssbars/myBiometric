import '../domain/models/delegation_of_authority.dart';

/// Service managing temporary delegation of approval authority
class DelegationOfAuthorityService {
  /// Validates a proposed delegation before creation
  static String? validateDelegation({
    required String delegatorUserId,
    required String delegateeUserId,
    required DateTime effectiveFrom,
    required DateTime effectiveUntil,
  }) {
    if (delegatorUserId == delegateeUserId) {
      return 'Cannot delegate authority to oneself';
    }
    if (!effectiveUntil.isAfter(effectiveFrom)) {
      return 'Effective end date must be strictly after start date';
    }
    return null;
  }

  /// Determines if a user currently has acting authority for a given department and scope
  static bool hasActingAuthority({
    required List<AuthorityDelegationRecord> delegations,
    required String userId,
    required String departmentId,
    required DelegationScope requiredScope,
    DateTime? atTime,
  }) {
    final checkTime = atTime ?? DateTime.now();

    return delegations.any((d) {
      if (d.delegateeUserId != userId) return false;
      if (d.departmentId != departmentId) return false;
      if (!d.isEffectiveAt(checkTime)) return false;

      if (d.scope == DelegationScope.fullAdministrative) return true;
      return d.scope == requiredScope;
    });
  }

  /// Retrieves all active acting delegations for a designated user
  static List<AuthorityDelegationRecord> getActiveDelegationsForUser({
    required List<AuthorityDelegationRecord> delegations,
    required String userId,
    DateTime? atTime,
  }) {
    final checkTime = atTime ?? DateTime.now();
    return delegations
        .where((d) => d.delegateeUserId == userId && d.isEffectiveAt(checkTime))
        .toList();
  }

  /// Returns the human-readable description for a delegation scope
  static String getScopeDescription(DelegationScope scope) {
    switch (scope) {
      case DelegationScope.leaveApproval:
        return 'Leave Applications Only';
      case DelegationScope.regularizationApproval:
        return 'Attendance Regularizations Only';
      case DelegationScope.shiftManagement:
        return 'Shift Swaps & Rosters';
      case DelegationScope.fullAdministrative:
        return 'All Administrative Approvals';
    }
  }
}
