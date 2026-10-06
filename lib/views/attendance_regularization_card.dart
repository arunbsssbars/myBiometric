import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../core/utils/app_format_utils.dart';
import '../domain/models/attendance_regularization_request.dart';

/// Responsive Material 3 card displaying an attendance regularization request with
/// administrative actions (Approve, Reject). Built strictly to AQIL defensive layout standards.
class AttendanceRegularizationCard extends StatelessWidget {
  final AttendanceRegularizationRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final bool showActions;

  const AttendanceRegularizationCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive padding and constrained dimensions
    final horizontalPadding = (screenWidth * 0.04).clamp(10.0, 18.0);
    final statusBadgeMaxWidth = (screenWidth * 0.35).clamp(85.0, 140.0);

    // Date and time formatting using AppFormatUtils (ACHS DRY standard)
    final dateStr = '${request.targetDate.day.toString().padLeft(2, '0')}/${request.targetDate.month.toString().padLeft(2, '0')}/${request.targetDate.year}';
    final inTimeStr = AppFormatUtils.formatTimeAmPm(request.requestedCheckIn);
    final outTimeStr = AppFormatUtils.formatTimeAmPm(request.requestedCheckOut);
    final durationStr = AppFormatUtils.formatMinutesToHours(request.requestedDurationMinutes);

    // Meta string joined with AQIL single-text join
    final metaItems = <String>[
      request.category.label,
      dateStr,
      '$inTimeStr - $outTimeStr',
      durationStr,
    ];
    final metaString = metaItems.join(' • ');

    // Color and icon resolution based on status
    final Color statusColor;
    final IconData statusIcon;
    switch (request.status) {
      case RegularizationStatus.approved:
        statusColor = context.status.success.color;
        statusIcon = Icons.check_circle_rounded;
        break;
      case RegularizationStatus.rejected:
        statusColor = context.colors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      case RegularizationStatus.pending:
        statusColor = context.status.warning.color;
        statusIcon = Icons.pending_actions_rounded;
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Avatar/Icon + Employee Info + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          request.employeeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          metaString,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: statusBadgeMaxWidth),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        request.status.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Reason Description Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  request.reasonDescription.isNotEmpty
                      ? request.reasonDescription
                      : 'No specific notes provided.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontStyle: request.reasonDescription.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),

              // Review Notes (if already reviewed)
              if (request.reviewNotes != null && request.reviewNotes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Reviewer Notes: ${request.reviewNotes}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],

              // Administrative Action Buttons (if pending and actions enabled) - Wrapped defensively with AQIL standards
              if (showActions && request.status == RegularizationStatus.pending) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 15),
                        label: const Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(70, 32),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.status.success.color,
                          foregroundColor: context.colors.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(80, 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
