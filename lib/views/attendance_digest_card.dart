import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/daily_attendance_digest.dart';

/// Responsive Material 3 card presenting end-of-day attendance health and anomaly alerts.
/// Built strictly adhering to the AQIL responsive standard (single text joining,
/// proportional constraints, ellipsis safeguards).
class AttendanceDigestCard extends StatelessWidget {
  final DailyAttendanceDigest digest;
  final VoidCallback? onViewAnomalies;

  const AttendanceDigestCard({
    super.key,
    required this.digest,
    this.onViewAnomalies,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Proportional horizontal padding
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);
    final metricWidth = (screenWidth * 0.28).clamp(80.0, 140.0);

    // Build subtitle safely using AQIL single-text join
    final metaItems = <String>[
      '${digest.totalHeadcount} staff scheduled',
      '${digest.attendanceRatePercent.toStringAsFixed(0)}% attendance',
      '${digest.onTimeRatePercent.toStringAsFixed(0)}% on-time',
    ];
    final metaString = metaItems.join(' • ');

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
                  child: Icon(Icons.analytics_rounded, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Daily Attendance Digest',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        metaString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onViewAnomalies != null && digest.hasCriticalAnomalies)
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onViewAnomalies,
                    tooltip: 'View anomaly details',
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Key Metrics
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetricChip(
                  context,
                  width: metricWidth,
                  label: 'Present',
                  value: '${digest.presentCount}',
                  color: context.status.success.color,
                  icon: Icons.check_circle_rounded,
                ),
                _buildMetricChip(
                  context,
                  width: metricWidth,
                  label: 'Late Arrivals',
                  value: '${digest.lateCount}',
                  color: digest.lateCount > 0 ? context.status.warning.color : context.colors.onSurfaceVariant,
                  icon: Icons.access_time_rounded,
                ),
                _buildMetricChip(
                  context,
                  width: metricWidth,
                  label: 'Absent',
                  value: '${digest.absentCount}',
                  color: digest.absentCount > 0 ? context.status.danger.color : context.colors.onSurfaceVariant,
                  icon: Icons.person_off_rounded,
                ),
              ],
            ),

            // Critical Anomalies Warning Banner
            if (digest.hasCriticalAnomalies) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.status.warning.container,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.status.warning.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: context.status.warning.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${digest.unclosedShiftsCount} unclosed shifts • ${digest.overstayedBreaksCount} break overstays',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: context.status.warning.onContainer,
                          fontWeight: FontWeight.bold,
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
