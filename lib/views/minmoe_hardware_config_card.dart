import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/minmoe_hardware_config.dart';

/// Card presenting Hikvision MinMoe optical parameters, liveness mode, and lighting levels
class MinMoeHardwareConfigCard extends StatelessWidget {
  final MinMoeHardwareConfig config;
  final VoidCallback? onApplyConfig;

  const MinMoeHardwareConfigCard({
    super.key,
    required this.config,
    this.onApplyConfig,
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
                Icon(Icons.camera_alt_outlined, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Hikvision MinMoe Optics & Audio',
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
                    config.livenessMode.name.toUpperCase(),
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.status.success.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'IP: ${config.deviceIp}:${config.httpPort} • Distance: ${config.recognitionDistanceCm}cm • Match: ${(config.faceMatchThreshold * 100).round()}%',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildTag(context, 'IR Illumination', config.irIlluminationEnabled),
                _buildTag(context, 'White Light (${config.whiteLightBrightnessPercent}%)', config.whiteLightSupplementEnabled),
                _buildTag(context, 'Audio Prompt (${config.volumeLevel}%)', true),
                _buildTag(context, 'Tamper Alarm', config.tamperAlarmEnabled),
              ],
            ),
            if (onApplyConfig != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: onApplyConfig,
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('Push ISAPI Config'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label, bool active) {
    final color = active ? context.status.success.color : context.colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle_outline : Icons.cancel_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: context.textStyles.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
