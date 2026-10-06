import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/device_mesh_sync_record.dart';

/// Card showing status and summary of P2P offline mesh sync between terminals
class DeviceMeshSyncCard extends StatelessWidget {
  final DeviceMeshSyncRecord syncRecord;
  final VoidCallback? onTriggerSync;

  const DeviceMeshSyncCard({
    super.key,
    required this.syncRecord,
    this.onTriggerSync,
  });

  IconData _getProtocolIcon(DeviceSyncProtocol protocol) {
    switch (protocol) {
      case DeviceSyncProtocol.lanDirectWebSocket:
        return Icons.lan_rounded;
      case DeviceSyncProtocol.bleMeshGatt:
        return Icons.bluetooth_searching_rounded;
      case DeviceSyncProtocol.p2pWifiDirect:
        return Icons.wifi_tethering_rounded;
    }
  }

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
                Icon(
                  _getProtocolIcon(syncRecord.protocol),
                  size: 22,
                  color: context.colors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'P2P Offline Mesh Sync',
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
                    'COMPLETED',
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
              'Peer: ${syncRecord.senderDeviceId} ➔ ${syncRecord.targetDeviceId}',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
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
                      Text('Transferred', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${syncRecord.recordsTransferred} logs',
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
                      Text('Resolved Conflicts', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${syncRecord.conflictsResolved}',
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
                      Text('Strategy', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        syncRecord.strategy.name,
                        style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
