import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/ble_beacon_profile.dart';

/// Responsive Material 3 card showing Bluetooth Low Energy (BLE) beacon detection telemetry.
/// Built strictly following AQIL v2 responsive standards.
class BleBeaconTelemetryCard extends StatelessWidget {
  final BeaconVerificationResult result;
  final VoidCallback? onScanAgain;

  const BleBeaconTelemetryCard({
    super.key,
    required this.result,
    this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final Color statusColor;
    final String statusLabel;

    if (result.isVerified) {
      statusColor = context.status.success.color;
      statusLabel = 'BEACON VERIFIED';
    } else if (result.matchedBeacon != null) {
      statusColor = context.status.warning.color;
      statusLabel = 'WEAK SIGNAL';
    } else {
      statusColor = context.status.danger.color;
      statusLabel = 'NO BEACON';
    }

    final distanceStr = result.estimatedDistanceMeters.isFinite
        ? '~${result.estimatedDistanceMeters.toStringAsFixed(1)}m distance'
        : 'Unknown distance';

    final metaItems = <String>[
      if (result.matchedBeacon != null) result.matchedBeacon!.name else 'BLE Scanning',
      if (result.measuredRssi != -100) '${result.measuredRssi} dBm',
      distanceStr,
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.bluetooth_searching_rounded,
                    color: statusColor,
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
                        'Indoor BLE Presence Gate',
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    statusLabel,
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                result.statusDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onScanAgain != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onScanAgain,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Rescan Beacons'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
