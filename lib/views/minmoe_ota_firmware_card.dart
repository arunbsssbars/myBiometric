import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/minmoe_firmware_package.dart';

/// Card presenting Hikvision MinMoe OTA firmware package and upgrade progress
class MinMoeOtaFirmwareCard extends StatelessWidget {
  final MinMoeFirmwarePackage package;
  final MinMoeOtaProgress? progress;
  final VoidCallback? onTriggerUpgrade;

  const MinMoeOtaFirmwareCard({
    super.key,
    required this.package,
    this.progress,
    this.onTriggerUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isFlashing = progress != null &&
        (progress!.status == MinMoeOtaStatus.flashing ||
            progress!.status == MinMoeOtaStatus.downloading);

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
                Icon(Icons.system_update_rounded, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'MinMoe Firmware OTA',
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
                    package.firmwareVersion,
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Model: ${package.modelName} • ${(package.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isFlashing) ...[
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: (progress!.percentComplete / 100.0).clamp(0.0, 1.0),
                color: context.colors.primary,
              ),
              const SizedBox(height: 4),
              Text(
                'Flashing: ${progress!.percentComplete}% (${progress!.status.name})',
                style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: context.colors.primary),
              ),
            ] else if (onTriggerUpgrade != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: onTriggerUpgrade,
                  icon: const Icon(Icons.install_mobile_rounded, size: 14),
                  label: const Text('Start OTA Flash'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
