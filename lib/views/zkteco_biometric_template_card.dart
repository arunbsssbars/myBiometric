import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/zkteco_biometric_template.dart';

/// Card presenting ZKTeco biometric template registration parameters and push state
class ZktecoBiometricTemplateCard extends StatelessWidget {
  final ZktecoBiometricTemplate template;
  final VoidCallback? onPushToMachine;

  const ZktecoBiometricTemplateCard({
    super.key,
    required this.template,
    this.onPushToMachine,
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
                Icon(Icons.fingerprint_rounded, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Employee PIN: ${template.pin}',
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
                    'FINGER #${template.fingerId}',
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
              'Algorithm: ${template.algorithm.name.toUpperCase()} • Template Size: ${template.templateSize} bytes',
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
                    'TMP: ${template.templateBase64.substring(0, 16)}...',
                    style: context.textStyles.labelSmall?.copyWith(fontFamily: 'monospace', color: context.colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onPushToMachine != null)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: onPushToMachine,
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text('Sync Template'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
