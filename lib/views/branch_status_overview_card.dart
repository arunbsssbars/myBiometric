import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/enterprise_branch.dart';

/// Responsive Material 3 card displaying enterprise branch hierarchy and geofence status.
/// Built strictly following AQIL v2 responsive standards.
class BranchStatusOverviewCard extends StatelessWidget {
  final EnterpriseBranch branch;
  final BranchGeofenceEvaluation? currentEvaluation;
  final VoidCallback? onManageBranch;

  const BranchStatusOverviewCard({
    super.key,
    required this.branch,
    this.currentEvaluation,
    this.onManageBranch,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final isWithin = currentEvaluation?.isWithinGeofence ?? false;
    final isAuthorized = currentEvaluation?.isAuthorizedForEmployee ?? false;

    final Color statusColor;
    final String statusLabel;

    if (currentEvaluation == null) {
      statusColor = context.colors.textSecondary;
      statusLabel = branch.isActive ? 'ACTIVE BRANCH' : 'INACTIVE';
    } else if (isWithin && isAuthorized) {
      statusColor = context.status.success.color;
      statusLabel = 'IN GEOFENCE';
    } else if (isWithin && !isAuthorized) {
      statusColor = context.status.warning.color;
      statusLabel = 'UNAUTHORIZED BRANCH';
    } else {
      statusColor = context.status.danger.color;
      statusLabel = 'OUT OF BOUNDS';
    }

    final metaItems = <String>[
      'Code: ${branch.code}',
      'Radius: ${branch.geofenceRadiusMeters.toStringAsFixed(0)}m',
      '${branch.assignedTerminalIds.length} Terminals',
      if (branch.timezone != null) branch.timezone!,
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
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    color: context.colors.primary,
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
                        branch.name,
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
            if (currentEvaluation != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: context.colors.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  currentEvaluation!.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            if (onManageBranch != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onManageBranch,
                  icon: const Icon(Icons.settings_outlined, size: 14),
                  label: const Text('Configure Branch'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
