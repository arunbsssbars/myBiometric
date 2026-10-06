import 'package:flutter/foundation.dart';

enum DeviceComplianceTier {
  fedrampHigh,
  iso27001,
  soc2Type2,
  gdprStrict,
  hipaaSecurity,
}

enum ComplianceAuditStatus {
  passed,
  advisory,
  remediationRequired,
}

/// Regulatory framework verification result for workforce hardware terminal operations
@immutable
class TerminalComplianceScorecard {
  final String scorecardId;
  final String enterpriseId;
  final DeviceComplianceTier tier;
  final ComplianceAuditStatus status;
  final int overallScorePercent; // 0 to 100
  final bool dataAtRestEncrypted;
  final bool dataInTransitEncryptedTls13;
  final bool biometricTemplatesSaltedAndHashed;
  final bool employeeConsentCaptured;
  final bool zeroKnowledgeVectorStorage;
  final DateTime auditedAt;

  const TerminalComplianceScorecard({
    required this.scorecardId,
    required this.enterpriseId,
    required this.tier,
    required this.status,
    required this.overallScorePercent,
    required this.dataAtRestEncrypted,
    required this.dataInTransitEncryptedTls13,
    required this.biometricTemplatesSaltedAndHashed,
    required this.employeeConsentCaptured,
    required this.zeroKnowledgeVectorStorage,
    required this.auditedAt,
  });

  bool get isApprovedForEnterprise =>
      status == ComplianceAuditStatus.passed && overallScorePercent >= 90;

  Map<String, dynamic> toMap() => {
        'scorecardId': scorecardId,
        'enterpriseId': enterpriseId,
        'tier': tier.name,
        'status': status.name,
        'overallScorePercent': overallScorePercent,
        'dataAtRestEncrypted': dataAtRestEncrypted,
        'dataInTransitEncryptedTls13': dataInTransitEncryptedTls13,
        'biometricTemplatesSaltedAndHashed': biometricTemplatesSaltedAndHashed,
        'employeeConsentCaptured': employeeConsentCaptured,
        'zeroKnowledgeVectorStorage': zeroKnowledgeVectorStorage,
        'auditedAt': auditedAt.toIso8601String(),
      };

  factory TerminalComplianceScorecard.fromMap(Map<String, dynamic> map) =>
      TerminalComplianceScorecard(
        scorecardId: map['scorecardId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        tier: DeviceComplianceTier.values.firstWhere(
          (e) => e.name == map['tier'],
          orElse: () => DeviceComplianceTier.soc2Type2,
        ),
        status: ComplianceAuditStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ComplianceAuditStatus.passed,
        ),
        overallScorePercent: (map['overallScorePercent'] as num?)?.toInt() ?? 100,
        dataAtRestEncrypted: map['dataAtRestEncrypted'] as bool? ?? true,
        dataInTransitEncryptedTls13: map['dataInTransitEncryptedTls13'] as bool? ?? true,
        biometricTemplatesSaltedAndHashed: map['biometricTemplatesSaltedAndHashed'] as bool? ?? true,
        employeeConsentCaptured: map['employeeConsentCaptured'] as bool? ?? true,
        zeroKnowledgeVectorStorage: map['zeroKnowledgeVectorStorage'] as bool? ?? true,
        auditedAt: map['auditedAt'] != null
            ? DateTime.tryParse(map['auditedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
