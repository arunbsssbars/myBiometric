import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/labor_law_compliance.dart';

/// Responsive Material 3 card visualizing statutory labor law and rest period compliance.
/// Built strictly following AQIL v2 responsive standards.
class LaborLawComplianceCard extends StatelessWidget {
  final ComplianceEvaluationResult evaluation;
  final VoidCallback? onViewDetails;

  const LaborLawComplianceCard({
    super.key,
    required this.evaluation,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final Color statusColor;
    final String statusLabel;

    if (evaluation.isCompliant) {
      statusColor = context.status.success.color;
      statusLabel = 'COMPLIANT';
    } else if (evaluation.hasBlockingViolation) {
      statusColor = context.status.danger.color;
      statusLabel = 'BLOCKING VIOLATION';
    } else {
      statusColor = context.status.warning.color;
      statusLabel = '${evaluation.violations.length} VIOLATIONS';
    }

    final restText = evaluation.restHoursSinceLastOut.isFinite
        ? '${evaluation.restHoursSinceLastOut.toStringAsFixed(1)}h rest'
        : 'First shift';

    final metaItems = <String>[
      restText,
      '${evaluation.consecutiveWorkingDays} consecutive days',
      if (evaluation.violations.isNotEmpty)
        '${evaluation.violations.length} findings',
    ];
    final metaString = metaItems.join(' • ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: context.colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: context.colors.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    evaluation.isCompliant
                        ? Icons.gavel_rounded
                        : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: AppSizes.iconMd,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Labor Law & Rest Compliance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        metaString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    statusLabel,
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                evaluation.summaryMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (evaluation.violations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              ...evaluation.violations.take(2).map((v) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right_rounded,
                          size: 16,
                          color: context.colors.textSecondary,
                        ),
                        Expanded(
                          child: Text(
                            v.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (onViewDetails != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.shield_outlined, size: 14),
                  label: const Text('Compliance Breakdown'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
