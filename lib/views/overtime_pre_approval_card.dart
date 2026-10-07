import 'package:flutter/material.dart';
import '../services/overtime_pre_approval_service.dart';
import '../core/design_system/design_system.dart';

class OvertimePreApprovalCard extends StatelessWidget {
  final OvertimePreApprovalRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const OvertimePreApprovalCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPending = request.status == OvertimeRequestStatus.pending;
    final isApproved = request.status == OvertimeRequestStatus.approved;

    final badgeColor = isApproved
        ? Colors.green
        : isPending
            ? Colors.orange
            : colors.error;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timelapse_rounded,
                  color: badgeColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.employeeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    request.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${request.department} • +${request.plannedHours.toStringAsFixed(1)} hrs • ${request.category.name}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              request.justification,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isPending && (onApprove != null || onReject != null)) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: colors.error),
                        onPressed: onReject,
                        child: const Text('Reject', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (onApprove != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          foregroundColor: Colors.green.shade800,
                        ),
                        onPressed: onApprove,
                        child: const Text('Approve', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
