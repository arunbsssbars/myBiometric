/// Scope of delegated authority granted to a substitute reviewer
enum DelegationScope {
  leaveApproval,
  regularizationApproval,
  shiftManagement,
  fullAdministrative,
}

/// Lifecycle status of an authority delegation agreement
enum DelegationStatus {
  pending,
  active,
  expired,
  revoked,
}

/// Record designating temporary transfer of approval authority
class AuthorityDelegationRecord {
  final String delegationId;
  final String enterpriseId;
  final String departmentId;
  final String delegatorUserId;
  final String delegatorName;
  final String delegateeUserId;
  final String delegateeName;
  final DelegationScope scope;
  final DateTime effectiveFrom;
  final DateTime effectiveUntil;
  final String reason;
  final DelegationStatus status;
  final DateTime createdAt;

  const AuthorityDelegationRecord({
    required this.delegationId,
    required this.enterpriseId,
    required this.departmentId,
    required this.delegatorUserId,
    required this.delegatorName,
    required this.delegateeUserId,
    required this.delegateeName,
    required this.scope,
    required this.effectiveFrom,
    required this.effectiveUntil,
    required this.reason,
    this.status = DelegationStatus.active,
    required this.createdAt,
  });

  /// Evaluates whether the delegation is active at a given timestamp
  bool isEffectiveAt(DateTime timestamp) {
    if (status != DelegationStatus.active) return false;
    return timestamp.isAfter(effectiveFrom) && timestamp.isBefore(effectiveUntil);
  }

  Map<String, dynamic> toMap() => {
    'delegationId': delegationId,
    'enterpriseId': enterpriseId,
    'departmentId': departmentId,
    'delegatorUserId': delegatorUserId,
    'delegatorName': delegatorName,
    'delegateeUserId': delegateeUserId,
    'delegateeName': delegateeName,
    'scope': scope.name,
    'effectiveFrom': effectiveFrom.toIso8601String(),
    'effectiveUntil': effectiveUntil.toIso8601String(),
    'reason': reason,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AuthorityDelegationRecord.fromMap(Map<String, dynamic> map) {
    return AuthorityDelegationRecord(
      delegationId: map['delegationId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      departmentId: map['departmentId'] as String? ?? '',
      delegatorUserId: map['delegatorUserId'] as String? ?? '',
      delegatorName: map['delegatorName'] as String? ?? 'Manager',
      delegateeUserId: map['delegateeUserId'] as String? ?? '',
      delegateeName: map['delegateeName'] as String? ?? 'Acting Manager',
      scope: DelegationScope.values.firstWhere(
        (e) => e.name == map['scope'],
        orElse: () => DelegationScope.fullAdministrative,
      ),
      effectiveFrom: map['effectiveFrom'] != null
          ? DateTime.tryParse(map['effectiveFrom'] as String) ?? DateTime.now()
          : DateTime.now(),
      effectiveUntil: map['effectiveUntil'] != null
          ? DateTime.tryParse(map['effectiveUntil'] as String) ?? DateTime.now()
          : DateTime.now(),
      reason: map['reason'] as String? ?? 'Temporary delegation',
      status: DelegationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DelegationStatus.active,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
