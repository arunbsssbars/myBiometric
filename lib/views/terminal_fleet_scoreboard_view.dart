import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/terminal_fleet_analytics.dart';

/// Responsive view presenting the enterprise hardware terminal fleet health scoreboard,
/// SLA availability gauge, and morning rush-hour throughput distribution.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalFleetScoreboardView extends StatelessWidget {
  final TerminalFleetAnalyticsReport report;

  const TerminalFleetScoreboardView({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    final uptimeColor = report.fleetUptimePercent >= 99.0
        ? statusTheme.success.color
        : report.fleetUptimePercent >= 90.0
            ? statusTheme.warning.color
            : statusTheme.danger.color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.analytics_rounded, color: colors.primary, size: AppSizes.iconSm),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fleet SLA & Health Scoreboard',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${report.onlineTerminals}/${report.totalTerminals} terminals active',
                      style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: uptimeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: uptimeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${report.fleetUptimePercent}% SLA',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: uptimeColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 3 Metric Tiles
          Row(
            children: [
              Expanded(
                child: _buildScoreTile(
                  context,
                  label: "Today's Punches",
                  value: '${report.totalPunchesToday}',
                  icon: Icons.fingerprint_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildScoreTile(
                  context,
                  label: 'Peak Hour',
                  value: '${report.peakHour.toString().padLeft(2, '0')}:00',
                  icon: Icons.timer_outlined,
                  color: statusTheme.info.color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildScoreTile(
                  context,
                  label: 'Face Match Avg',
                  value: '${report.averageFaceSimilarityScore}%',
                  icon: Icons.face_rounded,
                  color: statusTheme.success.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Mini Hourly Throughput Distribution Indicator
          Text(
            'Daily Peak Traffic Distribution',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: report.hourlyThroughput.where((b) => b.hourOfDay >= 6 && b.hourOfDay <= 21).map((bucket) {
                final heightFraction = report.peakHourPunchCount > 0
                    ? (bucket.totalPunches / report.peakHourPunchCount).clamp(0.15, 1.0)
                    : 0.2;

                final isPeak = bucket.hourOfDay == report.peakHour && bucket.totalPunches > 0;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    height: 36 * heightFraction,
                    decoration: BoxDecoration(
                      color: isPeak ? colors.primary : colors.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colors = context.colors;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconSm * 0.8, color: color),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
