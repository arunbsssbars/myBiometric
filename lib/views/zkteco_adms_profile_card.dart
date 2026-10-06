import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/zkteco_adms_profile.dart';

/// Card presenting ZKTeco ADMS IClock cloud push status and communication interval
class ZktecoAdmsProfileCard extends StatelessWidget {
  final ZktecoAdmsProfile profile;
  final VoidCallback? onSendOptions;

  const ZktecoAdmsProfileCard({
    super.key,
    required this.profile,
    this.onSendOptions,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.router_rounded, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'ZKTeco ADMS Server Push',
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
                    color: context.status.success.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    profile.protocol.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.status.success.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'SN: ${profile.deviceSerialNumber} • IP: ${profile.deviceIp} • FW: ${profile.firmwareVersion}',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Heartbeat', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.heartbeatIntervalSeconds}s',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Push Mode', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        profile.realTimePushEnabled ? 'Real-Time' : 'Batch Poll',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Template Sync', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        profile.biometricTemplateSyncEnabled ? 'Enabled' : 'Disabled',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
