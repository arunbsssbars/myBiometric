import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../services/regularization_sla_service.dart';

/// Responsive Material 3 card summarizing attendance regularization SLA compliance and aging.
/// Built strictly following AQIL v2 responsive standards.
class RegularizationSlaStatusCard extends StatelessWidget {
  final RegularizationSlaSummary summary;
  final VoidCallback? onReviewQueue;

  const RegularizationSlaStatusCard({
    super.key,
    required this.summary,
    this.onReviewQueue,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final hasCritical = summary.breachedCount > 0 || summary.escalatedCount > 0;
    final Color statusColor;
    final String statusLabel;

    if (hasCritical) {
      statusColor = context.status.danger.color;
      statusLabel = '${summary.breachedCount + summary.escalatedCount} ESCALATED/BREACHED';
    } else if (summary.warningCount > 0) {
      statusColor = context.status.warning.color;
      statusLabel = '${summary.warningCount} EXPIRING SOON';
    } else {
      statusColor = context.status.success.color;
      statusLabel = 'ALL WITHIN SLA';
    }

    final metaItems = <String>[
      '${summary.totalPending} Pending Requests',
      'Avg Aging: ${summary.averageAgingHours.toStringAsFixed(1)}h',
      if (summary.escalatedCount > 0) '${summary.escalatedCount} Escalated',
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
                    hasCritical ? Icons.alarm_on_rounded : Icons.timer_outlined,
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
                        'Regularization SLA Tracker',
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildMetricChip(
                  context: context,
                  label: '${summary.withinSlaCount} On Time',
                  color: context.status.success.color,
                ),
                _buildMetricChip(
                  context: context,
                  label: '${summary.warningCount} Warning',
                  color: context.status.warning.color,
                ),
                _buildMetricChip(
                  context: context,
                  label: '${summary.breachedCount} Breached',
                  color: context.status.danger.color,
                ),
                _buildMetricChip(
                  context: context,
                  label: '${summary.escalatedCount} Escalated',
                  color: context.colors.error,
                ),
              ],
            ),
            if (onReviewQueue != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onReviewQueue,
                  icon: const Icon(Icons.playlist_play_rounded, size: 14),
                  label: const Text('Review SLA Queue'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required BuildContext context,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
