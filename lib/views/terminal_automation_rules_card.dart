import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/terminal_automation_rule.dart';

/// Responsive card displaying a terminal automation rule, its schedule window,
/// natural jitter variance indicator, active days chips, and manual simulation action.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalAutomationRulesCard extends StatelessWidget {
  final TerminalAutomationRule rule;
  final String terminalName;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onSimulateNow;
  final VoidCallback? onEdit;

  const TerminalAutomationRulesCard({
    super.key,
    required this.rule,
    required this.terminalName,
    this.onToggleActive,
    this.onSimulateNow,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: rule.isActive
              ? colors.primary.withValues(alpha: 0.5)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
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
                  color: (rule.isActive ? colors.primary : colors.onSurfaceVariant).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.auto_mode_rounded,
                  color: rule.isActive ? colors.primary : colors.onSurfaceVariant,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.employeeName.isNotEmpty ? rule.employeeName : 'Terminal Automation Rule',
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$terminalName • ${rule.shiftStartTime} - ${rule.shiftEndTime} • ID: ${rule.employeeId}',
                      style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: rule.isActive,
                onChanged: onToggleActive,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Schedule Details Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.login_rounded, size: 14, color: statusTheme.success.color),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'In: ${rule.shiftStartTime} (±${rule.jitterMinutes}m)',
                          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 14, color: colors.error),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Out: ${rule.shiftEndTime} (±${rule.jitterMinutes}m)',
                          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Weekday Chips
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: List.generate(7, (i) {
              final dayIndex = i + 1;
              final isDayActive = rule.activeWeekdays.contains(dayIndex);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: isDayActive
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: isDayActive ? colors.primary.withValues(alpha: 0.5) : Colors.transparent,
                  ),
                ),
                child: Text(
                  weekdayNames[i],
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: isDayActive ? FontWeight.bold : FontWeight.normal,
                    color: isDayActive ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                  ),
                ),
              );
            }),
          ),

          if (onSimulateNow != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSimulateNow,
                icon: const Icon(Icons.play_circle_outline_rounded, size: AppSizes.iconSm),
                label: const Text(
                  'Simulate Hardware Punch Now',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
