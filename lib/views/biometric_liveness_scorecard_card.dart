import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/biometric_liveness_audit.dart';

/// Responsive Material 3 card displaying multi-spectrum biometric anti-spoofing telemetry.
/// Built strictly following AQIL v2 responsive standards.
class BiometricLivenessScorecardCard extends StatelessWidget {
  final BiometricLivenessScorecard scorecard;
  final VoidCallback? onAuditTelemetry;

  const BiometricLivenessScorecardCard({
    super.key,
    required this.scorecard,
    this.onAuditTelemetry,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final isConfirmed = scorecard.isLiveHumanConfirmed;
    final statusColor = isConfirmed ? context.status.success.color : context.status.danger.color;
    final statusLabel = isConfirmed ? 'LIVE HUMAN' : 'SPOOF DETECTED';

    final scorePercent = (scorecard.aggregateLivenessScore * 100).toStringAsFixed(0);
    final spoofPercent = (scorecard.spoofProbability * 100).toStringAsFixed(0);

    final metaItems = <String>[
      'Liveness: $scorePercent%',
      'Spoof Risk: $spoofPercent%',
      '${scorecard.vectors.length} Sensor Channels',
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
                    isConfirmed ? Icons.verified_user_rounded : Icons.shield_rounded,
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
                        'Anti-Spoofing & Liveness',
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
              children: scorecard.vectors.map((v) {
                final color = v.passedThreshold ? context.status.success.color : context.status.danger.color;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        v.passedThreshold ? Icons.check_circle_outline : Icons.highlight_off_rounded,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${v.modality.name.toUpperCase()}: ${(v.confidenceScore * 100).toInt()}%',
                        style: context.textStyles.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (!isConfirmed && scorecard.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.status.danger.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: context.status.danger.color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  scorecard.rejectionReason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.status.danger.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (onAuditTelemetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onAuditTelemetry,
                  icon: const Icon(Icons.analytics_outlined, size: 14),
                  label: const Text('View Raw Vector Data'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
