import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/shift_automation_policy.dart';

/// Responsive Material 3 card displaying enterprise shift automation rules
/// (Auto Clock-Out and Meal Deductions). Built strictly to AQIL defensive layout standards.
class ShiftAutomationCard extends StatelessWidget {
  final ShiftAutomationPolicy policy;
  final VoidCallback? onConfigure;

  const ShiftAutomationCard({
    super.key,
    required this.policy,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Proportional horizontal padding
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);
    final badgeWidth = (screenWidth * 0.42).clamp(120.0, 200.0);

    // Build subtitle safely using AQIL single-text join
    final metaItems = <String>[
      if (policy.autoClockOutEnabled) 'Max ${policy.autoClockOutMaxShiftHours}h shift cap',
      if (policy.autoClockOutAtShiftEnd) 'Strict shift cutoff',
      if (policy.autoDeductLunchEnabled) '${policy.autoDeductLunchMinutes}m lunch deduction',
      if (!policy.autoClockOutEnabled && !policy.autoDeductLunchEnabled) 'Automations paused',
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
                  child: Icon(Icons.alarm_on_rounded, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shift Closure & Deductions',
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
                if (onConfigure != null)
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: onConfigure,
                    tooltip: 'Configure automation policies',
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Automation Status Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAutomationPill(
                  context,
                  width: badgeWidth,
                  label: 'Auto Clock-Out',
                  status: policy.autoClockOutEnabled ? 'Enabled' : 'Disabled',
                  isActive: policy.autoClockOutEnabled,
                  icon: Icons.logout_rounded,
                ),
                _buildAutomationPill(
                  context,
                  width: badgeWidth,
                  label: 'Auto Lunch Deduction',
                  status: policy.autoDeductLunchEnabled ? '${policy.autoDeductLunchMinutes} min' : 'Disabled',
                  isActive: policy.autoDeductLunchEnabled,
                  icon: Icons.restaurant_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationPill(
    BuildContext context, {
    required double width,
    required String label,
    required String status,
    required bool isActive,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final color = isActive ? context.status.success.color : context.colors.onSurfaceVariant;

    return Container(
      constraints: BoxConstraints(minWidth: width),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
