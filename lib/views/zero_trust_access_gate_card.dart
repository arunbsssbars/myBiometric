import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/zero_trust_access_evaluation.dart';

/// Card presenting comprehensive zero-trust posture signals and gate decision
class ZeroTrustAccessGateCard extends StatelessWidget {
  final ZeroTrustAccessEvaluation evaluation;

  const ZeroTrustAccessGateCard({
    super.key,
    required this.evaluation,
  });

  @override
  Widget build(BuildContext context) {
    final isGranted = evaluation.isAccessGranted;
    final statusColor = isGranted ? context.status.success.color : context.status.danger.color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isGranted ? context.colors.borderSubtle : context.status.danger.color.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGranted ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
                  size: 22,
                  color: statusColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Zero-Trust Contextual Gate',
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
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    isGranted ? 'ACCESS GRANTED' : 'ACCESS DENIED',
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              evaluation.decisionReason,
              style: context.textStyles.bodySmall?.copyWith(
                color: isGranted ? context.colors.textSecondary : context.status.danger.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildSignalChip(context, 'Biometrics', evaluation.confidenceScore >= 0.85),
                _buildSignalChip(context, 'Device Posture', evaluation.isDevicePostureCompliant),
                _buildSignalChip(context, 'Geofence', evaluation.isLocationWithinGeofence),
                _buildSignalChip(context, 'mTLS Client', evaluation.isMtlsAuthenticated),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalChip(BuildContext context, String label, bool passed) {
    final color = passed ? context.status.success.color : context.status.danger.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(passed ? Icons.check_circle_outline : Icons.cancel_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: context.textStyles.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
