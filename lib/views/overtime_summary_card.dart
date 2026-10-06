import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../services/overtime_calculation_service.dart';

/// Responsive Material 3 card displaying regular vs multi-tier overtime breakdown.
/// Built strictly adhering to the AQIL defensive layout standard (single text joining,
/// proportional constraints, ellipsis safeguards).
class OvertimeSummaryCard extends StatelessWidget {
  final OvertimeBreakdown breakdown;
  final String title;
  final VoidCallback? onTapDetails;

  const OvertimeSummaryCard({
    super.key,
    required this.breakdown,
    this.title = 'Overtime & Hours Summary',
    this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Proportional clamped horizontal padding
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);
    // Proportional badge min-width
    final metricItemWidth = (screenWidth * 0.28).clamp(90.0, 160.0);

    // Build joined metadata string safely (AQIL Single-Text Pattern)
    final metaItems = <String>[
      '${breakdown.dailyResults.length} days logged',
      if (breakdown.totalWeeklyOtMinutes > 0) '${breakdown.weeklyOtHours.toStringAsFixed(1)}h weekly OT',
      if (breakdown.totalRestDayMinutes > 0) '${breakdown.restDayHours.toStringAsFixed(1)}h rest day',
    ];
    final joinedMeta = metaItems.join(' • ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.access_time_filled, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (joinedMeta.isNotEmpty)
                        Text(
                          joinedMeta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTapDetails != null)
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onTapDetails,
                    tooltip: 'View daily log breakdown',
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics Row: Regular, Overtime, Weighted Total
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildMetricChip(
                  context,
                  width: metricItemWidth,
                  label: 'Regular Hours',
                  value: breakdown.formattedRegularHours,
                  color: colorScheme.primary,
                  icon: Icons.check_circle_outline,
                ),
                _buildMetricChip(
                  context,
                  width: metricItemWidth,
                  label: 'Overtime (1.5x/2x)',
                  value: breakdown.formattedOvertimeHours,
                  color: breakdown.totalOvertimeHours > 0 ? context.status.warning.color : colorScheme.outline,
                  icon: Icons.trending_up,
                ),
                _buildMetricChip(
                  context,
                  width: metricItemWidth,
                  label: 'Weighted Pay',
                  value: breakdown.formattedWeightedHours,
                  color: context.colors.tertiary,
                  icon: Icons.payments_outlined,
                ),
              ],
            ),

            if (breakdown.totalDailyDoubleOtMinutes > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.status.danger.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: context.status.danger.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Includes ${breakdown.doubleOtHours.toStringAsFixed(1)} hrs Double Overtime (2.0x)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.status.danger.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(
    BuildContext context, {
    required double width,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(minWidth: width),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
