import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/device_kiosk_security_policy.dart';

/// Card presenting terminal lock-down status and system navigation suppression controls
class DeviceKioskSecurityCard extends StatelessWidget {
  final DeviceKioskSecurityPolicy policy;
  final VoidCallback? onConfigure;

  const DeviceKioskSecurityCard({
    super.key,
    required this.policy,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final isStrict = policy.mode == DeviceKioskPolicyMode.strictKiosk;

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
                  Icons.lock_clock_rounded,
                  size: 22,
                  color: isStrict ? context.colors.primary : context.status.warning.color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Kiosk Lockdown Enforcement',
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
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    policy.mode.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip(context, 'Status Bar Locked', policy.disableStatusBar),
                _buildChip(context, 'Home Button Locked', policy.disableHomeButton),
                _buildChip(context, 'Power Menu Disabled', policy.disablePowerMenu),
                _buildChip(context, 'Auto-Relaunch Active', policy.autoRelaunchOnCrash),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, bool active) {
    final color = active ? context.status.success.color : context.colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle_outline : Icons.cancel_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
