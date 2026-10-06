import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/enterprise_holiday_calendar.dart';

/// Responsive Material 3 card showing upcoming enterprise holidays and holiday overtime rates.
/// Built strictly following AQIL v2 responsive standards.
class HolidayCalendarOverviewCard extends StatelessWidget {
  final List<EnterpriseHoliday> upcomingHolidays;
  final VoidCallback? onManageHolidays;

  const HolidayCalendarOverviewCard({
    super.key,
    required this.upcomingHolidays,
    this.onManageHolidays,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final nextHoliday = upcomingHolidays.isNotEmpty ? upcomingHolidays.first : null;

    final metaItems = <String>[
      '${upcomingHolidays.length} Upcoming Holidays',
      if (nextHoliday != null) 'Next: ${nextHoliday.title}',
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
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: context.colors.primary,
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
                        'Enterprise Holiday Calendar',
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
                    color: context.status.success.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'CALENDAR ACTIVE',
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.status.success.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (upcomingHolidays.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No upcoming holidays scheduled for the remainder of the cycle.',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              )
            else
              ...upcomingHolidays.take(3).map((holiday) {
                final dateStr = '${holiday.date.day}/${holiday.date.month}/${holiday.date.year}';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          dateStr,
                          style: context.textStyles.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          holiday.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${holiday.overtimeMultiplier}× OT Rate',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (onManageHolidays != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onManageHolidays,
                  icon: const Icon(Icons.calendar_month_outlined, size: 14),
                  label: const Text('Manage Calendar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
