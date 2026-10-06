import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/shift_swap_request.dart';

/// AQIL-hardened component for displaying a peer shift swap request.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class ShiftSwapCard extends StatelessWidget {
  final ShiftSwapRequest swap;
  final String currentUserId;
  final VoidCallback? onPeerAccept;
  final VoidCallback? onPeerReject;
  final VoidCallback? onManagerApprove;
  final VoidCallback? onManagerReject;
  final VoidCallback? onCancel;

  const ShiftSwapCard({
    super.key,
    required this.swap,
    required this.currentUserId,
    this.onPeerAccept,
    this.onPeerReject,
    this.onManagerApprove,
    this.onManagerReject,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusTheme = context.status;
    final colors = context.colors;
    final textTheme = context.text;

    Color badgeColor;
    Color badgeBg;

    switch (swap.status) {
      case ShiftSwapStatus.pendingPeer:
        badgeColor = statusTheme.warning.color;
        badgeBg = statusTheme.warning.container;
        break;
      case ShiftSwapStatus.pendingManager:
        badgeColor = colors.primary;
        badgeBg = colors.primaryContainer;
        break;
      case ShiftSwapStatus.approved:
        badgeColor = statusTheme.success.color;
        badgeBg = statusTheme.success.container;
        break;
      case ShiftSwapStatus.rejectedByPeer:
      case ShiftSwapStatus.rejectedByManager:
      case ShiftSwapStatus.cancelled:
        badgeColor = statusTheme.danger.color;
        badgeBg = statusTheme.danger.container;
        break;
    }

    final isTargetPeer = swap.targetEmployeeId == currentUserId;
    final isRequester = swap.requesterId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Creation Date Header
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      swap.statusDisplay,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${swap.createdAt.day}/${swap.createdAt.month}/${swap.createdAt.year}',
                  style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Swap Partner Comparison Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          swap.requesterName,
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${swap.requesterDate.day}/${swap.requesterDate.month}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          swap.requesterShiftName,
                          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Icon(Icons.swap_horiz_rounded, size: AppSizes.iconMd, color: colors.primary),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          swap.targetEmployeeName,
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${swap.targetDate.day}/${swap.targetDate.month}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          swap.targetShiftName,
                          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (swap.reason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reason: ${swap.reason}',
                style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action Buttons
            if (isTargetPeer && swap.isPendingPeer) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton(
                    onPressed: onPeerReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Decline'),
                  ),
                  FilledButton(
                    onPressed: onPeerAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: statusTheme.success.color,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ] else if (swap.isPendingManager && onManagerApprove != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton(
                    onPressed: onManagerReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: onManagerApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ] else if (isRequester && swap.isPendingPeer && onCancel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: Icon(Icons.cancel_outlined, size: AppSizes.iconSm, color: colors.onSurfaceVariant),
                  label: Text('Cancel Request', style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
