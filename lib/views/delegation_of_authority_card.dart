import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/delegation_of_authority.dart';
import '../services/delegation_of_authority_service.dart';

/// Responsive Material 3 card displaying active or pending Delegation of Authority.
/// Built strictly following AQIL v2 responsive standards.
class DelegationOfAuthorityCard extends StatelessWidget {
  final AuthorityDelegationRecord delegation;
  final VoidCallback? onRevoke;

  const DelegationOfAuthorityCard({
    super.key,
    required this.delegation,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final isEffective = delegation.isEffectiveAt(DateTime.now());
    final Color statusColor;
    final String statusLabel;

    if (delegation.status == DelegationStatus.revoked) {
      statusColor = context.status.danger.color;
      statusLabel = 'REVOKED';
    } else if (isEffective) {
      statusColor = context.status.success.color;
      statusLabel = 'ACTIVE ACTING';
    } else if (delegation.effectiveFrom.isAfter(DateTime.now())) {
      statusColor = context.status.warning.color;
      statusLabel = 'SCHEDULED';
    } else {
      statusColor = context.colors.textSecondary;
      statusLabel = 'EXPIRED';
    }

    final fromStr = '${delegation.effectiveFrom.day}/${delegation.effectiveFrom.month}/${delegation.effectiveFrom.year}';
    final untilStr = '${delegation.effectiveUntil.day}/${delegation.effectiveUntil.month}/${delegation.effectiveUntil.year}';

    final metaItems = <String>[
      'Dept: ${delegation.departmentId}',
      '$fromStr – $untilStr',
      DelegationOfAuthorityService.getScopeDescription(delegation.scope),
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
                    Icons.supervisor_account_rounded,
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
                        '${delegation.delegatorName} ➔ ${delegation.delegateeName}',
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
                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: context.colors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Reason: ${delegation.reason}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            if (onRevoke != null && isEffective) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onRevoke,
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Revoke Delegation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
