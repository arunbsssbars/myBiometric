import 'package:flutter/material.dart';
import '../services/edge_bandwidth_optimizer_service.dart';
import '../core/design_system/design_system.dart';

class EdgeBandwidthOptimizerCard extends StatelessWidget {
  final BandwidthQuotaConfig config;
  final SyncCompressionStats? latestStats;
  final VoidCallback? onResetQuota;

  const EdgeBandwidthOptimizerCard({
    super.key,
    required this.config,
    this.latestStats,
    this.onResetQuota,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCellular = config.syncMode == NetworkSyncMode.meteredCellular;
    final isExceeded = config.isQuotaExceeded;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExceeded
              ? colors.error
              : isCellular
                  ? Colors.blue.shade300
                  : colors.outlineVariant,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCellular ? Icons.cell_tower_rounded : Icons.lan_rounded,
                  color: isExceeded ? colors.error : colors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terminal Bandwidth: ${config.deviceId}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isExceeded ? colors.error : colors.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    config.syncMode.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isExceeded ? colors.error : colors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${config.currentUsageMb.toStringAsFixed(1)} MB / ${config.monthlyLimitMb.toStringAsFixed(0)} MB',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(config.quotaUsagePercentage * 100).toInt()}% used',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isExceeded ? colors.error : colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: config.quotaUsagePercentage,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded ? colors.error : colors.primary,
              ),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            if (latestStats != null) ...[
              const SizedBox(height: 8),
              Text(
                'Compression: ${( (1 - latestStats!.compressionRatio) * 100 ).toInt()}% saved (${latestStats!.rawBytes}B → ${latestStats!.compressedBytes}B)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
