/// Severity level of labor law compliance findings
enum ComplianceSeverity {
  warning,
  violation,
  blocking,
}

/// Type of labor law check evaluated
enum ComplianceRuleType {
  minimumRestPeriod,
  maximumConsecutiveDays,
  maximumDailyHours,
  weeklyOvertimeCap,
  nightShiftProtection,
}

/// Detailed violation record
class ComplianceViolation {
  final ComplianceRuleType ruleType;
  final ComplianceSeverity severity;
  final String title;
  final String description;
  final DateTime evaluatedAt;
  final Map<String, dynamic> metadata;

  const ComplianceViolation({
    required this.ruleType,
    required this.severity,
    required this.title,
    required this.description,
    required this.evaluatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() => {
    'ruleType': ruleType.name,
    'severity': severity.name,
    'title': title,
    'description': description,
    'evaluatedAt': evaluatedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory ComplianceViolation.fromMap(Map<String, dynamic> map) {
    return ComplianceViolation(
      ruleType: ComplianceRuleType.values.firstWhere(
        (e) => e.name == map['ruleType'],
        orElse: () => ComplianceRuleType.minimumRestPeriod,
      ),
      severity: ComplianceSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => ComplianceSeverity.warning,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      evaluatedAt: map['evaluatedAt'] != null
          ? DateTime.tryParse(map['evaluatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }
}

/// Statutory Labor Law Policy rules configured per enterprise or jurisdiction
class LaborLawPolicy {
  final String policyId;
  final String enterpriseId;
  final String jurisdictionName;
  final double minimumRestPeriodHours; // e.g. 11.0 hours between shifts
  final int maxConsecutiveWorkingDays; // e.g. 6 days before mandatory rest
  final double maxDailyWorkHours; // e.g. 12.0 hours
  final double maxWeeklyOvertimeHours; // e.g. 16.0 hours
  final bool enforceBlockingOnShiftPunch; // Blocks punch if rest period violated
  final bool isEnabled;

  const LaborLawPolicy({
    required this.policyId,
    required this.enterpriseId,
    this.jurisdictionName = 'Standard Statutory',
    this.minimumRestPeriodHours = 11.0,
    this.maxConsecutiveWorkingDays = 6,
    this.maxDailyWorkHours = 12.0,
    this.maxWeeklyOvertimeHours = 16.0,
    this.enforceBlockingOnShiftPunch = false,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() => {
    'policyId': policyId,
    'enterpriseId': enterpriseId,
    'jurisdictionName': jurisdictionName,
    'minimumRestPeriodHours': minimumRestPeriodHours,
    'maxConsecutiveWorkingDays': maxConsecutiveWorkingDays,
    'maxDailyWorkHours': maxDailyWorkHours,
    'maxWeeklyOvertimeHours': maxWeeklyOvertimeHours,
    'enforceBlockingOnShiftPunch': enforceBlockingOnShiftPunch,
    'isEnabled': isEnabled,
  };

  factory LaborLawPolicy.fromMap(Map<String, dynamic> map) {
    return LaborLawPolicy(
      policyId: map['policyId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      jurisdictionName: map['jurisdictionName'] as String? ?? 'Standard Statutory',
      minimumRestPeriodHours: (map['minimumRestPeriodHours'] as num?)?.toDouble() ?? 11.0,
      maxConsecutiveWorkingDays: (map['maxConsecutiveWorkingDays'] as num?)?.toInt() ?? 6,
      maxDailyWorkHours: (map['maxDailyWorkHours'] as num?)?.toDouble() ?? 12.0,
      maxWeeklyOvertimeHours: (map['maxWeeklyOvertimeHours'] as num?)?.toDouble() ?? 16.0,
      enforceBlockingOnShiftPunch: map['enforceBlockingOnShiftPunch'] as bool? ?? false,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }
}

/// Evaluation result summarizing statutory compliance status
class ComplianceEvaluationResult {
  final bool isCompliant;
  final bool hasBlockingViolation;
  final List<ComplianceViolation> violations;
  final double restHoursSinceLastOut;
  final int consecutiveWorkingDays;
  final String summaryMessage;

  const ComplianceEvaluationResult({
    required this.isCompliant,
    required this.hasBlockingViolation,
    required this.violations,
    required this.restHoursSinceLastOut,
    required this.consecutiveWorkingDays,
    required this.summaryMessage,
  });
}
