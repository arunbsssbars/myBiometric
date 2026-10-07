import 'package:flutter/material.dart';
import '../services/terminal_environment_sensor_service.dart';
import '../core/design_system/design_system.dart';

class TerminalEnvironmentSensorCard extends StatelessWidget {
  final TerminalEnvironmentTelemetry telemetry;

  const TerminalEnvironmentSensorCard({
    super.key,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = telemetry.operatingState;

    final badgeColor = state == SensorOperatingState.critical
        ? colors.error
        : state == SensorOperatingState.warning
            ? Colors.orange
            : Colors.green;

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
                  state == SensorOperatingState.optimal
                      ? Icons.thermostat_rounded
                      : Icons.warning_amber_rounded,
                  color: badgeColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Environment: ${telemetry.deviceId}',
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
                    state.name.toUpperCase(),
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
              '${telemetry.temperatureCelsius.toStringAsFixed(1)}°C • ${telemetry.ambientLightLux.toStringAsFixed(0)} Lux • ${telemetry.relativeHumidityPercent.toStringAsFixed(0)}% RH',
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
              telemetry.environmentStatusSummary,
              style: TextStyle(
                fontSize: 12,
                color: state == SensorOperatingState.optimal
                    ? colors.onSurfaceVariant
                    : badgeColor,
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
