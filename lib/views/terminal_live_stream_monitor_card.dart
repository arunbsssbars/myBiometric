import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/terminal_live_alert.dart';

/// Responsive card displaying a real-time live alert event from an external biometric machine,
/// featuring threat indicators, door relay states, and defensive text safeguards.
/// Fully token-driven (AQIL v2): Zero hardcoded hex colors or fonts.
class TerminalLiveStreamMonitorCard extends StatelessWidget {
  final TerminalLiveAlert alert;
  final VoidCallback? onTap;

  const TerminalLiveStreamMonitorCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    final timeStr = '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}:${alert.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: alert.isSecurityThreat
            ? alert.alertColor.withAlpha(20)
            : colors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: alert.alertColor.withAlpha(alert.isSecurityThreat ? 120 : 60),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: alert.alertColor.withAlpha(30),
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(alert.alertIcon, size: AppSizes.iconSm, color: alert.alertColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.employeeName ?? alert.description,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      timeStr,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${alert.deviceName} • ${alert.description}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (alert.similarityScore != null || alert.isDoorUnlocked) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      if (alert.similarityScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                          decoration: BoxDecoration(
                            color: alert.alertColor.withAlpha(20),
                            borderRadius: AppRadius.brXs,
                          ),
                          child: Text(
                            'Confidence: ${alert.similarityScore!.toStringAsFixed(1)}%',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: alert.alertColor,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                        decoration: BoxDecoration(
                          color: (alert.isDoorUnlocked ? statusTheme.success.color : colors.outline).withAlpha(20),
                          borderRadius: AppRadius.brXs,
                        ),
                        child: Text(
                          alert.isDoorUnlocked ? 'Door Relay: UNLOCKED' : 'Door Relay: LOCKED',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: alert.isDoorUnlocked ? statusTheme.success.color : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
