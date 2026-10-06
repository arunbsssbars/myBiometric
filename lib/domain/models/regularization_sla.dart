/// SLA stage for attendance regularization tickets
enum SlaStatus {
  withinSla,
  warning, // approaching expiration (e.g., > 75% elapsed)
  breached, // exceeded time limit
  escalated, // transferred to senior admin/HR
}

/// Enterprise policy configuration for ticket SLAs
class RegularizationSlaConfig {
  final String enterpriseId;
  final int slaTargetHours; // e.g. 48 hours
  final int warningThresholdHours; // e.g. 36 hours
  final bool autoEscalateOnBreach;
  final String escalationTargetRole; // 'enterprise_admin' or 'hr_director'

  const RegularizationSlaConfig({
    required this.enterpriseId,
    this.slaTargetHours = 48,
    this.warningThresholdHours = 36,
    this.autoEscalateOnBreach = true,
    this.escalationTargetRole = 'enterprise_admin',
  });

  Map<String, dynamic> toMap() => {
    'enterpriseId': enterpriseId,
    'slaTargetHours': slaTargetHours,
    'warningThresholdHours': warningThresholdHours,
    'autoEscalateOnBreach': autoEscalateOnBreach,
    'escalationTargetRole': escalationTargetRole,
  };

  factory RegularizationSlaConfig.fromMap(Map<String, dynamic> map) {
    return RegularizationSlaConfig(
      enterpriseId: map['enterpriseId'] as String? ?? '',
      slaTargetHours: (map['slaTargetHours'] as num?)?.toInt() ?? 48,
      warningThresholdHours: (map['warningThresholdHours'] as num?)?.toInt() ?? 36,
      autoEscalateOnBreach: map['autoEscalateOnBreach'] as bool? ?? true,
      escalationTargetRole: map['escalationTargetRole'] as String? ?? 'enterprise_admin',
    );
  }
}

/// SLA state evaluated for an individual regularization ticket
class RegularizationTicketSla {
  final String ticketId;
  final String employeeName;
  final DateTime submittedAt;
  final SlaStatus status;
  final double elapsedHours;
  final double remainingHours;
  final bool isEscalated;
  final String statusDescription;

  const RegularizationTicketSla({
    required this.ticketId,
    required this.employeeName,
    required this.submittedAt,
    required this.status,
    required this.elapsedHours,
    required this.remainingHours,
    required this.isEscalated,
    required this.statusDescription,
  });
}
