import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';

/// AQIL-hardened card for displaying an external biometric hardware terminal.
class TerminalDeviceCard extends StatelessWidget {
  final BiometricTerminalDevice device;
  final VoidCallback? onTestConnection;
  final VoidCallback? onSyncNow;
  final VoidCallback? onProvisionUsers;
  final VoidCallback? onProbeDiagnostics;
  final VoidCallback? onSyncTemplates;
  final VoidCallback? onRemoteControl;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TerminalDeviceCard({
    super.key,
    required this.device,
    this.onTestConnection,
    this.onSyncNow,
    this.onProvisionUsers,
    this.onProbeDiagnostics,
    this.onSyncTemplates,
    this.onRemoteControl,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColors = context.status;
    StatusTone tone;
    String statusLabel;

    switch (device.status) {
      case DeviceConnectionStatus.online:
        tone = statusColors.success;
        statusLabel = 'ONLINE';
        break;
      case DeviceConnectionStatus.offline:
        tone = statusColors.neutral;
        statusLabel = 'OFFLINE';
        break;
      case DeviceConnectionStatus.syncing:
        tone = statusColors.info;
        statusLabel = 'SYNCING';
        break;
      case DeviceConnectionStatus.error:
        tone = statusColors.danger;
        statusLabel = 'AUTH ERROR';
        break;
      case DeviceConnectionStatus.unregistered:
        tone = statusColors.warning;
        statusLabel = 'UNREGISTERED';
        break;
    }

    final metadataParts = <String>[
      device.modelName,
      '${device.ipAddress}:${device.port}',
      if (device.branchName != null && device.branchName!.isNotEmpty) device.branchName!,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: context.colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Device Name, Status Badge, Overflow Menu
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.fingerprint_rounded, color: context.colors.primary, size: AppSizes.iconSm),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        metadataParts.join(' • '),
                        style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: tone.container,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: tone.border),
                  ),
                  child: Text(
                    statusLabel,
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tone.onContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Protocol & Event Count Tags
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.settings_ethernet_rounded, size: AppSizes.iconXs, color: context.colors.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(
                          device.protocolDisplayName,
                          style: context.text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: statusColors.success.container,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: statusColors.success.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync_rounded, size: AppSizes.iconXs, color: statusColors.success.color),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(
                          '${device.totalEventsSynced} Punches Synced',
                          style: context.text.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: statusColors.success.onContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: context.colors.outlineVariant),
            const SizedBox(height: AppSpacing.xs),

            // Action Buttons
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                if (onTestConnection != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(60, AppSizes.minTouchTarget),
                    ),
                    icon: Icon(Icons.wifi_tethering_rounded, size: AppSizes.iconXs, color: context.colors.primary),
                    label: Text('Test', style: context.text.labelMedium?.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600)),
                    onPressed: onTestConnection,
                  ),
                if (onSyncNow != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(60, AppSizes.minTouchTarget),
                    ),
                    icon: Icon(Icons.download_rounded, size: AppSizes.iconXs, color: statusColors.success.color),
                    label: Text('Pull Logs', style: context.text.labelMedium?.copyWith(color: statusColors.success.color, fontWeight: FontWeight.w600)),
                    onPressed: onSyncNow,
                  ),
                if (onProvisionUsers != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(60, AppSizes.minTouchTarget),
                    ),
                    icon: Icon(Icons.person_add_alt_1_rounded, size: AppSizes.iconXs, color: context.colors.tertiary),
                    label: Text('Push Staff', style: context.text.labelMedium?.copyWith(color: context.colors.tertiary, fontWeight: FontWeight.w600)),
                    onPressed: onProvisionUsers,
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: AppSizes.iconSm, color: context.colors.onSurfaceVariant),
                  tooltip: 'Terminal Operations',
                  constraints: const BoxConstraints(minWidth: AppSizes.minTouchTarget, minHeight: AppSizes.minTouchTarget),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'probe') onProbeDiagnostics?.call();
                    if (val == 'templates') onSyncTemplates?.call();
                    if (val == 'remote') onRemoteControl?.call();
                    if (val == 'edit') onEdit?.call();
                    if (val == 'delete') onDelete?.call();
                  },
                  itemBuilder: (ctx) => [
                    if (onProbeDiagnostics != null)
                      PopupMenuItem(
                        value: 'probe',
                        child: Row(
                          children: [
                            Icon(Icons.troubleshoot_rounded, size: AppSizes.iconSm, color: context.colors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Hardware Diagnostics', style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                    if (onSyncTemplates != null)
                      PopupMenuItem(
                        value: 'templates',
                        child: Row(
                          children: [
                            Icon(Icons.face_retouching_natural_rounded, size: AppSizes.iconSm, color: statusColors.success.color),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Sync Face Templates', style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                    if (onRemoteControl != null)
                      PopupMenuItem(
                        value: 'remote',
                        child: Row(
                          children: [
                            Icon(Icons.settings_remote_rounded, size: AppSizes.iconSm, color: context.colors.secondary),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Remote Door & Audio', style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: AppSizes.iconSm, color: context.colors.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Edit Configuration', style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: AppSizes.iconSm, color: statusColors.danger.color),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Remove Terminal', style: context.text.bodyMedium?.copyWith(color: statusColors.danger.color)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
