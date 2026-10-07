import 'package:flutter/material.dart';
import '../services/terminal_tamper_alert_service.dart';
import '../core/design_system/design_system.dart';

class TerminalTamperAlertCard extends StatelessWidget {
  final TerminalTamperEvent event;
  final VoidCallback? onAcknowledge;

  const TerminalTamperAlertCard({
    super.key,
    required this.event,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCritical = event.severity == TamperSeverity.critical;
    final isWarning = event.severity == TamperSeverity.warning;

    final badgeColor = isCritical
        ? colors.error
        : isWarning
            ? Colors.orange
            : colors.primary;

    final containerColor = isCritical
        ? colors.error.withValues(alpha: 0.08)
        : colors.surface;

    return Card(
      elevation: 0,
      color: containerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: event.acknowledged
              ? colors.outlineVariant.withValues(alpha: 0.5)
              : badgeColor.withValues(alpha: 0.5),
          width: event.acknowledged ? 1 : 1.5,
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
                  isCritical ? Icons.gpp_bad_rounded : Icons.warning_amber_rounded,
                  color: badgeColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device: ${event.deviceId}',
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
                    event.severity.name.toUpperCase(),
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
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${event.sensorType.name} • Val: ${event.sensorValue.toStringAsFixed(1)} • ${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!event.acknowledged && onAcknowledge != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        foregroundColor: badgeColor,
                      ),
                      onPressed: onAcknowledge,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'Acknowledge',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else if (event.acknowledged)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.done_all, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Acknowledged',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
