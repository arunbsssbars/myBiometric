import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/device_mdm_policy.dart';

/// Card presenting device posture and compliance with enterprise MDM security policy
class DeviceMdmAuditCard extends StatelessWidget {
  final DeviceMdmAuditReport auditReport;
  final VoidCallback? onRemediate;

  const DeviceMdmAuditCard({
    super.key,
    required this.auditReport,
    this.onRemediate,
  });

  @override
  Widget build(BuildContext context) {
    final isCompliant = auditReport.isCompliant;
    final statusColor = isCompliant ? context.status.success.color : context.status.danger.color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCompliant ? context.colors.borderSubtle : context.status.danger.color.withValues(alpha: 0.3),
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
                  isCompliant ? Icons.security_rounded : Icons.gpp_bad_rounded,
                  size: 22,
                  color: statusColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'MDM Enterprise Posture',
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
                    isCompliant ? 'COMPLIANT' : 'NON-COMPLIANT',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (isCompliant)
              Text(
                'Device satisfies all hardware encryption, biometric, and security flags.',
                style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else ...[
              Text(
                'Violations Detected (${auditReport.violations.length}):',
                style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: context.status.danger.color),
              ),
              const SizedBox(height: 4),
              ...auditReport.violations.map((v) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.close_rounded, size: 14, color: context.status.danger.color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            v,
                            style: context.text.bodySmall?.copyWith(color: context.colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
