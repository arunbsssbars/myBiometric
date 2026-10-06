import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/rolling_roster_pattern.dart';

/// Responsive Material 3 card displaying employee's rolling shift forecast.
/// Built strictly following AQIL v2 responsive standards.
class RollingRosterScheduleCard extends StatelessWidget {
  final RollingRosterPattern pattern;
  final List<ProjectedShiftAssignment> projectedShifts;
  final VoidCallback? onAdjustRoster;

  const RollingRosterScheduleCard({
    super.key,
    required this.pattern,
    required this.projectedShifts,
    this.onAdjustRoster,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final todayShift = projectedShifts.isNotEmpty ? projectedShifts.first : null;

    final Color statusColor;
    final String statusLabel;

    if (todayShift == null || todayShift.step.isRestDay) {
      statusColor = context.status.info.color;
      statusLabel = 'SCHEDULED OFF';
    } else {
      statusColor = context.status.success.color;
      statusLabel = todayShift.step.shiftName.toUpperCase();
    }

    final metaItems = <String>[
      pattern.name,
      '${pattern.cycleLengthDays}-Day Rotation Cycle',
      '${projectedShifts.length}-Day Projection',
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
                    Icons.published_with_changes_rounded,
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
                        'Rolling Shift Roster',
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: projectedShifts.take(7).map((assignment) {
                  final isOff = assignment.step.isRestDay;
                  final dayColor = isOff ? context.colors.textSecondary : context.colors.primary;
                  final dateText = '${assignment.date.day}/${assignment.date.month}';

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: dayColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(color: dayColor.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateText,
                          style: context.textStyles.labelSmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOff ? 'OFF' : assignment.step.cycleType.name[0].toUpperCase(),
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: dayColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (onAdjustRoster != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onAdjustRoster,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                  label: const Text('Configure Rotation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
