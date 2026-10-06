import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/registered_device.dart';

/// Card displaying an employee's bound device status with trust indicator and revoke action
class DeviceBindingCard extends StatelessWidget {
  final RegisteredDevice device;
  final VoidCallback? onRevoke;
  final VoidCallback? onVerify;

  const DeviceBindingCard({
    super.key,
    required this.device,
    this.onRevoke,
    this.onVerify,
  });

  Color _getStatusColor(BuildContext context, DeviceTrustStatus status) {
    switch (status) {
      case DeviceTrustStatus.trusted:
        return context.status.success.color;
      case DeviceTrustStatus.pendingVerification:
        return context.status.warning.color;
      case DeviceTrustStatus.suspended:
        return context.status.neutral.color;
      case DeviceTrustStatus.quarantined:
        return context.status.danger.color;
    }
  }

  IconData _getPlatformIcon(DevicePlatformType platform) {
    switch (platform) {
      case DevicePlatformType.android:
        return Icons.phone_android_rounded;
      case DevicePlatformType.ios:
        return Icons.phone_iphone_rounded;
      case DevicePlatformType.web:
        return Icons.language_rounded;
      case DevicePlatformType.windows:
      case DevicePlatformType.macos:
      case DevicePlatformType.linux:
        return Icons.laptop_mac_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, device.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: device.status == DeviceTrustStatus.quarantined
              ? context.status.danger.color.withValues(alpha: 0.3)
              : context.colors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    _getPlatformIcon(device.platform),
                    size: 22,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.deviceName,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${device.model} • OS ${device.osVersion}',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    device.status.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (device.isJailbrokenOrRooted) ...[
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.status.danger.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: context.status.danger.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Security Alert: Rooted / Compromised device environment detected',
                        style: context.text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.status.danger.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Fingerprint: ${device.deviceFingerprintSha256.substring(0, 12)}...',
                    style: context.text.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onRevoke != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.status.danger.color,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onRevoke,
                    icon: const Icon(Icons.link_off_rounded, size: 16),
                    label: const Text('Revoke'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
