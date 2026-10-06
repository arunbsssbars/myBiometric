import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/enterprise_branch.dart';

/// AQIL-hardened card for rendering enterprise branch and job site location data.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class BranchLocationCard extends StatelessWidget {
  final EnterpriseBranch branch;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BranchLocationCard({
    super.key,
    required this.branch,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  branch.code,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  branch.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: branch.isActive ? statusTheme.success.container : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  branch.isActive ? 'Active' : 'Inactive',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: branch.isActive ? statusTheme.success.color : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: AppSizes.iconSm, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  branch.address.isNotEmpty ? branch.address : 'No street address specified',
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              _buildTag(
                context: context,
                icon: Icons.radar_rounded,
                label: '${branch.radiusMeters.toInt()}m Geofence',
                color: colors.primary,
                bgColor: colors.primaryContainer.withValues(alpha: 0.4),
              ),
              if (branch.allowedWifiSsids.isNotEmpty)
                _buildTag(
                  context: context,
                  icon: Icons.wifi_rounded,
                  label: '${branch.allowedWifiSsids.length} Wi-Fi SSID(s)',
                  color: statusTheme.info.color,
                  bgColor: statusTheme.info.container,
                ),
            ],
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(60, 36),
                      foregroundColor: colors.primary,
                    ),
                    icon: Icon(Icons.edit_outlined, size: AppSizes.iconSm, color: colors.primary),
                    label: Text('Edit', style: textTheme.labelSmall?.copyWith(color: colors.primary)),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(60, 36),
                      foregroundColor: statusTheme.danger.color,
                    ),
                    icon: Icon(Icons.delete_outline_rounded, size: AppSizes.iconSm, color: statusTheme.danger.color),
                    label: Text('Delete', style: textTheme.labelSmall?.copyWith(color: statusTheme.danger.color)),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    final textTheme = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm * 0.8, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
