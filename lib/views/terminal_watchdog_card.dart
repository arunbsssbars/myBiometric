import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/terminal_watchdog_incident.dart';

/// Card presenting hardware watchdog health metrics, self-healing status, and recovery events
class TerminalWatchdogCard extends StatelessWidget {
  final TerminalWatchdogMetrics metrics;
  final List<TerminalWatchdogIncident> recentIncidents;
  final VoidCallback? onTriggerSelfHealing;

  const TerminalWatchdogCard({
    super.key,
    required this.metrics,
    this.recentIncidents = const [],
    this.onTriggerSelfHealing,
  });

  Color _getStateColor(BuildContext context, DeviceHealthState state) {
    switch (state) {
      case DeviceHealthState.healthy:
        return context.status.success.color;
      case DeviceHealthState.warning:
        return context.status.warning.color;
      case DeviceHealthState.critical:
      case DeviceHealthState.offline:
        return context.status.danger.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthState = metrics.overallState;
    final stateColor = _getStateColor(context, healthState);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: healthState == DeviceHealthState.critical
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
                Icon(Icons.monitor_heart_rounded, size: 22, color: stateColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Hardware Watchdog Telemetry',
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
                    color: stateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    healthState.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: stateColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildMetricItem(context, 'RAM', '${metrics.ramUsagePercent.toStringAsFixed(0)}%'),
                _buildMetricItem(context, 'CPU', '${metrics.cpuUsagePercent.toStringAsFixed(0)}%'),
                _buildMetricItem(context, 'Disk Free', '${metrics.diskFreeMb.toStringAsFixed(0)}MB'),
                _buildMetricItem(context, 'Clock Drift', '${metrics.ntpDriftMillis}ms'),
              ],
            ),
            if (recentIncidents.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                'Autonomous Self-Healing Actions (${recentIncidents.length}):',
                style: context.textStyles.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...recentIncidents.take(2).map((inc) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          inc.autoRemediated ? Icons.check_circle_rounded : Icons.pending_rounded,
                          size: 14,
                          color: inc.autoRemediated ? context.status.success.color : context.status.warning.color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${inc.category}: ${inc.remediationAction ?? inc.message}',
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
