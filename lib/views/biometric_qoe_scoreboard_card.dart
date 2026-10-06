import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';

/// Card showing biometric verification speed, p95 latency, and user experience score
class BiometricQoEScoreboardCard extends StatelessWidget {
  final Map<String, dynamic> qoeStats;
  final VoidCallback? onRefresh;

  const BiometricQoEScoreboardCard({
    super.key,
    required this.qoeStats,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final avgLatency = qoeStats['averageLatencyMs'] ?? 0;
    final p95 = qoeStats['p95LatencyMs'] ?? 0;
    final successRate = qoeStats['successRate'] ?? 100.0;
    final isFast = avgLatency <= 450;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 22,
                  color: isFast ? context.status.success.color : context.status.warning.color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Biometric Experience Scoreboard',
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
                    color: isFast
                        ? context.status.success.color.withValues(alpha: 0.12)
                        : context.status.warning.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    isFast ? 'OPTIMAL' : 'MONITOR',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isFast ? context.status.success.color : context.status.warning.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avg Latency', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${avgLatency}ms',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('P95 Latency', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${p95}ms',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pass Rate', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '$successRate%',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
