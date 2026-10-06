import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/terminal_anti_passback_policy.dart';

/// Responsive configuration card for Anti-Passback (APB) and Dual-Door Interlocking policies.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalAntiPassbackSettingsCard extends StatelessWidget {
  final TerminalAntiPassbackPolicy policy;
  final ValueChanged<AntiPassbackMode>? onModeChanged;
  final ValueChanged<bool>? onInterlockChanged;
  final VoidCallback? onEdit;

  const TerminalAntiPassbackSettingsCard({
    super.key,
    required this.policy,
    this.onModeChanged,
    this.onInterlockChanged,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    Color modeColor;
    String modeLabel;

    switch (policy.mode) {
      case AntiPassbackMode.strict:
        modeColor = statusTheme.danger.color;
        modeLabel = 'STRICT REJECT';
        break;
      case AntiPassbackMode.soft:
        modeColor = statusTheme.warning.color;
        modeLabel = 'SOFT AUDIT';
        break;
      case AntiPassbackMode.disabled:
        modeColor = colors.onSurfaceVariant;
        modeLabel = 'DISABLED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: policy.isActive
              ? modeColor.withValues(alpha: 0.4)
              : colors.outlineVariant.withValues(alpha: 0.5),
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
                  color: modeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.shield_outlined, color: modeColor, size: AppSizes.iconSm),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.zoneName,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Auto-resets after ${policy.resetIntervalHours}h',
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
                  color: modeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  modeLabel,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: modeColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Segmented Mode Selector
          Row(
            children: [
              _buildModeOption(
                context,
                title: 'Strict',
                mode: AntiPassbackMode.strict,
                isSelected: policy.mode == AntiPassbackMode.strict,
                color: statusTheme.danger.color,
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildModeOption(
                context,
                title: 'Soft',
                mode: AntiPassbackMode.soft,
                isSelected: policy.mode == AntiPassbackMode.soft,
                color: statusTheme.warning.color,
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildModeOption(
                context,
                title: 'Off',
                mode: AntiPassbackMode.disabled,
                isSelected: policy.mode == AntiPassbackMode.disabled,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Dual Door Interlock Toggle Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.meeting_room_rounded, size: AppSizes.iconSm, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mantrap Interlocking',
                        style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Door 2 remains locked while Door 1 is open',
                        style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: policy.dualDoorInterlocking,
                  activeTrackColor: colors.primary,
                  onChanged: onInterlockChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required AntiPassbackMode mode,
    required bool isSelected,
    required Color color,
  }) {
    final colors = context.colors;
    final textTheme = context.text;

    return Expanded(
      child: InkWell(
        onTap: () => onModeChanged?.call(mode),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected ? color : colors.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
