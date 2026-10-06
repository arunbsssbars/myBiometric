import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../services/break_tracking_service.dart';

/// Reusable, overflow-proof workforce presence tile.
/// Visualizes live employee attendance status (Working, On Break, Overstayed,
/// Clocked Out, Absent, On Leave) with verification badges and running durations.
class EmployeePresenceTile extends StatelessWidget {
  final EmployeeDailySession session;
  final VoidCallback? onTap;
  final DateTime? nowOverride;

  const EmployeePresenceTile({
    super.key,
    required this.session,
    this.onTap,
    this.nowOverride,
  });

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatVerification(String v) {
    switch (v) {
      case 'DEVICE_TERMINAL':
      case 'HIKVISION_MINMOE':
      case 'ISAPI':
      case 'ZKTECO':
        return 'MinMoe Terminal';
      case 'MOBILE_GPS':
        return 'GPS';
      case 'KIOSK':
      case 'FACE_ID':
        return 'Face ID';
      case 'KIOSK_PIN':
        return 'PIN';
      case 'OFFICE_WIFI':
        return 'Office Wi-Fi';
      case 'PHONE_BIOMETRICS':
        return 'Biometrics';
      case 'ADMIN_MANUAL':
      case 'MANUAL':
        return 'Manual';
      default:
        return v;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.status;
    final colors = context.colors;

    StatusTone tone;
    String statusText;
    String durationText;
    IconData statusIcon;

    final currentTime = nowOverride ?? DateTime.now();

    switch (session.status) {
      case EmployeeWorkStatus.working:
        tone = status.success;
        statusText = 'WORKING';
        durationText = 'In at ${_formatTime(session.punchInTime)} • ${_formatDuration(session.netWorkDuration)}';
        statusIcon = Icons.work_rounded;
        break;
      case EmployeeWorkStatus.onBreak:
        final breakElapsed = session.breakStartTime != null
            ? currentTime.difference(session.breakStartTime!)
            : Duration.zero;
        if (session.isOverstayedBreak) {
          tone = status.danger;
          statusText = 'OVERSTAYED (+${session.overstayMinutes}m)';
          durationText = 'Break for ${_formatDuration(breakElapsed)} (Std: ${session.activeBreakCategory?.standardMinutes ?? 45}m)';
          statusIcon = Icons.warning_amber_rounded;
        } else {
          tone = status.warning;
          statusText = session.activeBreakCategory?.displayName.toUpperCase() ?? 'ON BREAK';
          durationText = 'Break for ${_formatDuration(breakElapsed)}';
          statusIcon = Icons.coffee_rounded;
        }
        break;
      case EmployeeWorkStatus.clockedOut:
        tone = status.neutral;
        statusText = 'CLOCKED OUT';
        durationText = 'Out at ${_formatTime(session.punchOutTime)} • ${_formatDuration(session.netWorkDuration)} total';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case EmployeeWorkStatus.absent:
        tone = status.danger;
        statusText = 'NOT IN';
        durationText = 'No attendance recorded today';
        statusIcon = Icons.remove_circle_outline_rounded;
        break;
      case EmployeeWorkStatus.onLeave:
        tone = status.info;
        statusText = 'ON LEAVE';
        durationText = session.leaveReason ?? 'Approved Leave';
        statusIcon = Icons.beach_access_rounded;
        break;
    }

    final initial = session.employeeName.isNotEmpty ? session.employeeName[0].toUpperCase() : 'E';

    return Semantics(
      button: true,
      label: '${session.employeeName}, $statusText, ${session.department}',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          child: Row(
            children: [
              // Avatar with Status Indicator Dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.surfaceContainerHigh,
                    child: Text(
                      initial,
                      style: context.text.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: tone.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),

              // Left Column: Name, Department & Verification Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.employeeName,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        session.employeeId,
                        if (session.department.isNotEmpty) session.department,
                        if (session.lastVerifiedVia != null) _formatVerification(session.lastVerifiedVia!),
                      ].join(' • '),
                      style: context.text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // Right Column: Status Pill & Duration
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.sizeOf(context).width * 0.36).clamp(80.0, 160.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: tone.container,
                        borderRadius: AppRadius.brSm,
                        border: Border.all(color: tone.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 10, color: tone.onContainer),
                          const SizedBox(width: 3),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: (MediaQuery.sizeOf(context).width * 0.24).clamp(65.0, 110.0),
                            ),
                            child: Text(
                              statusText,
                              style: context.text.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tone.onContainer,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      durationText,
                      style: context.text.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
