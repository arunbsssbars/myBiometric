import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/terminal_compliance_scorecard.dart';
import 'package:mybiometric_app/services/terminal_compliance_audit_service.dart';

void main() {
  group('TerminalComplianceAuditService Suite', () {
    const enterpriseId = 'ent_fintech_01';

    test('Passes 100% compliance audit when all zero-knowledge safeguards are active', () {
      final scorecard = TerminalComplianceAuditService.instance.performComplianceAudit(
        enterpriseId: enterpriseId,
        tier: DeviceComplianceTier.soc2Type2,
        isStorageEncrypted: true,
        isTls13Enforced: true,
        areBiometricsSalted: true,
        isConsentSigned: true,
        isZeroKnowledgeStorage: true,
      );

      expect(scorecard.isApprovedForEnterprise, isTrue);
      expect(scorecard.overallScorePercent, equals(100));
      expect(scorecard.status, equals(ComplianceAuditStatus.passed));
    });

    test('Flags remediation required when encryption or biometric salting are missing', () {
      final scorecard = TerminalComplianceAuditService.instance.performComplianceAudit(
        enterpriseId: enterpriseId,
        tier: DeviceComplianceTier.gdprStrict,
        isStorageEncrypted: false, // Critical failure
        isTls13Enforced: true,
        areBiometricsSalted: false, // Critical failure
        isConsentSigned: false,
        isZeroKnowledgeStorage: true,
      );

      expect(scorecard.isApprovedForEnterprise, isFalse);
      expect(scorecard.status, equals(ComplianceAuditStatus.remediationRequired));
      expect(scorecard.overallScorePercent, equals(40));
    });
  });
}
