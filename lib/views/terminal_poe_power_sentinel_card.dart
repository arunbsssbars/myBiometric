import 'package:flutter/material.dart';
import '../services/terminal_poe_power_sentinel_service.dart';
import '../core/design_system/design_system.dart';

class TerminalPoePowerSentinelCard extends StatelessWidget {
  final TerminalPowerStatus status;

  const TerminalPoePowerSentinelCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isOutage = status.isMainPowerLost;
    final isCrit = status.isCriticalBattery;

    final badgeColor = isCrit
        ? colors.error
        : isOutage
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: badgeColor.withValues(alpha: 0.4),
          width: isOutage ? 1.5 : 1.0,
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
                  isOutage ? Icons.battery_alert_rounded : Icons.bolt_rounded,
                  color: badgeColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Power: ${status.deviceId}',
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
                    isOutage ? 'BATTERY FAILOVER' : 'AC/PoE ONLINE',
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
              'Source: ${status.activePowerSource.name} • ${status.inputVoltage.toStringAsFixed(1)}V • ${status.currentDrawWatts.toStringAsFixed(1)}W draw',
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
              isOutage
                  ? 'Main grid lost! Running on internal Li-ion battery (~${status.estimatedBatteryMinutesRemaining} mins remaining @ ${status.batteryPercentage.toStringAsFixed(0)}%)'
                  : 'PoE power rail healthy. Backup battery fully charged (${status.batteryPercentage.toStringAsFixed(0)}%).',
              style: TextStyle(
                fontSize: 12,
                color: isOutage ? badgeColor : colors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
