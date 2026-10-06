import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/minmoe_face_enrollment_payload.dart';

/// Card presenting Hikvision MinMoe face model provisioning status and card credential binding
class MinMoeFaceEnrollmentCard extends StatelessWidget {
  final MinMoeFaceEnrollmentPayload payload;
  final VoidCallback? onEnrollToTerminal;

  const MinMoeFaceEnrollmentCard({
    super.key,
    required this.payload,
    this.onEnrollToTerminal,
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
                Icon(Icons.face_retouching_natural_rounded, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    payload.employeeName,
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
                    payload.mode.name.toUpperCase(),
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
              'Emp ID: ${payload.employeeNo} • Card No: ${payload.cardNo}',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dual-Auth: ${payload.enableDualAuthentication ? "ENABLED" : "DISABLED"}',
                  style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: context.colors.textSecondary),
                ),
                if (onEnrollToTerminal != null)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: onEnrollToTerminal,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 14),
                    label: const Text('Provision Face'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
