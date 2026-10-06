import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/terminal_compliance_scorecard.dart';

/// Card presenting SOC2 / ISO27001 regulatory compliance scorecard and cryptographic safeguards
class TerminalComplianceScorecardCard extends StatelessWidget {
  final TerminalComplianceScorecard scorecard;

  const TerminalComplianceScorecardCard({
    super.key,
    required this.scorecard,
  });

  Color _getStatusColor(BuildContext context, ComplianceAuditStatus status) {
    switch (status) {
      case ComplianceAuditStatus.passed:
        return context.status.success.color;
      case ComplianceAuditStatus.advisory:
        return context.status.warning.color;
      case ComplianceAuditStatus.remediationRequired:
        return context.status.danger.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, scorecard.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scorecard.status == ComplianceAuditStatus.remediationRequired
              ? context.status.danger.color.withValues(alpha: 0.3)
              : context.colors.borderSubtle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded, size: 22, color: statusColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${scorecard.tier.name.toUpperCase()} Compliance Audit',
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${scorecard.overallScorePercent}% SCORE',
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildSafeguardChip(context, 'TLS 1.3 In-Flight', scorecard.dataInTransitEncryptedTls13),
                _buildSafeguardChip(context, 'AES-256 At-Rest', scorecard.dataAtRestEncrypted),
                _buildSafeguardChip(context, 'Biometrics Salted', scorecard.biometricTemplatesSaltedAndHashed),
                _buildSafeguardChip(context, 'Zero-Knowledge Vectors', scorecard.zeroKnowledgeVectorStorage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeguardChip(BuildContext context, String label, bool satisfied) {
    final color = satisfied ? context.status.success.color : context.status.danger.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(satisfied ? Icons.check_circle_outline : Icons.cancel_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: context.textStyles.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
