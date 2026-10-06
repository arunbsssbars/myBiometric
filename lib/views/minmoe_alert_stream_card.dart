import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/minmoe_alert_event.dart';

/// Card presenting real-time Hikvision MinMoe optical alert stream events and liveness anti-spoof warnings
class MinMoeAlertStreamCard extends StatelessWidget {
  final MinMoeAlertEvent alert;
  final VoidCallback? onDismiss;

  const MinMoeAlertStreamCard({
    super.key,
    required this.alert,
    this.onDismiss,
  });

  Color _getSeverityColor(BuildContext context, MinMoeAlarmSeverity severity) {
    switch (severity) {
      case MinMoeAlarmSeverity.info:
        return context.colors.primary;
      case MinMoeAlarmSeverity.warning:
        return context.status.warning.color;
      case MinMoeAlarmSeverity.critical:
        return context.status.danger.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(context, alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: alert.severity == MinMoeAlarmSeverity.critical
              ? context.status.danger.color.withValues(alpha: 0.3)
              : context.colors.borderSubtle,
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
                  alert.severity == MinMoeAlarmSeverity.critical
                      ? Icons.warning_rounded
                      : Icons.notifications_active_outlined,
                  size: 22,
                  color: severityColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    alert.majorEventType,
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
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    alert.severity.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Terminal: ${alert.terminalId} • Emp: ${alert.employeeNo ?? "N/A"} • Card: ${alert.cardNo ?? "N/A"}',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (alert.faceMatchSimilarity != null && alert.faceMatchSimilarity! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Match Confidence: ${(alert.faceMatchSimilarity! * 100).round()}%',
                style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: context.colors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
