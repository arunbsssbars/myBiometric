import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/labor_compliance_policy.dart';

/// AQIL-hardened gauge score card for statutory labor compliance audits.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class ComplianceAuditScoreCard extends StatelessWidget {
  final ComplianceAuditReport report;
  final LaborCompliancePolicy policy;
  final VoidCallback onConfigurePolicy;

  const ComplianceAuditScoreCard({
    super.key,
    required this.report,
    required this.policy,
    required this.onConfigurePolicy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;
    final score = report.complianceScorePercent;

    Color scoreColor;
    if (score >= 90) {
      scoreColor = statusTheme.success.color;
    } else if (score >= 70) {
      scoreColor = statusTheme.warning.color;
    } else {
      scoreColor = statusTheme.danger.color;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statutory Compliance Score',
                        style: textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Text(
                            '${score.toStringAsFixed(0)}%',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: policy.isEnforced
                                  ? statusTheme.success.container
                                  : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                              border: Border.all(
                                color: policy.isEnforced
                                    ? statusTheme.success.border
                                    : colors.outlineVariant,
                              ),
                            ),
                            child: Text(
                              policy.isEnforced ? 'STRICT AUDIT ON' : 'AUDIT PAUSED',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: policy.isEnforced ? statusTheme.success.color : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onConfigurePolicy,
                  icon: const Icon(Icons.settings_outlined, size: AppSizes.iconMd),
                  tooltip: 'Configure Labor Policy Rules',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: (score / 100.0).clamp(0.0, 1.0),
                backgroundColor: colors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Metrics row
            Row(
              children: [
                Expanded(child: _buildStatItem(context, 'Violations', '${report.totalViolations}', statusTheme.danger.color)),
                Container(width: 1, height: 24, color: colors.outlineVariant.withValues(alpha: 0.5)),
                Expanded(child: _buildStatItem(context, 'Warnings', '${report.totalWarnings}', statusTheme.warning.color)),
                Container(width: 1, height: 24, color: colors.outlineVariant.withValues(alpha: 0.5)),
                Expanded(child: _buildStatItem(context, 'Clean Records', '${report.cleanRecordsCount}', statusTheme.success.color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    final textTheme = context.text;
    final colors = context.colors;

    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// AQIL-hardened incident card for compliance violations and warnings.
class ComplianceIncidentCard extends StatelessWidget {
  final ComplianceIncident incident;

  const ComplianceIncidentCard({
    super.key,
    required this.incident,
  });

  @override
  Widget build(BuildContext context) {
    final statusTheme = context.status;
    final colors = context.colors;
    final textTheme = context.text;

    final isViolation = incident.severity == ComplianceSeverity.violation;
    final badgeColor = isViolation ? statusTheme.danger.color : statusTheme.warning.color;
    final bgColor = isViolation ? statusTheme.danger.container : statusTheme.warning.container;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: badgeColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isViolation ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                  color: badgeColor,
                  size: AppSizes.iconMd,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    incident.issueTitle,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    isViolation ? 'VIOLATION' : 'WARNING',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              incident.description,
              style: textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.person_outline, size: AppSizes.iconXs, color: colors.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    '${incident.employeeName} • ${incident.timestamp.day}/${incident.timestamp.month}/${incident.timestamp.year}',
                    style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
