import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/device_telemetry_export_bundle.dart';

/// Card showing status and cryptographic checksum of archived telemetry bundles
class DeviceTelemetryExportCard extends StatelessWidget {
  final DeviceTelemetryExportBundle bundle;
  final VoidCallback? onDownload;

  const DeviceTelemetryExportCard({
    super.key,
    required this.bundle,
    this.onDownload,
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
                Icon(Icons.inventory_2_outlined, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'SIEM Telemetry Archive',
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
                    bundle.format.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${bundle.totalRecords} records • ${(bundle.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'SHA-256: ${bundle.sha256Checksum.substring(0, 16)}...',
                    style: context.text.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onDownload != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
