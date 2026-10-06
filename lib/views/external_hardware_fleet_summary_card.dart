import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/external_hardware_fleet_summary.dart';

/// Comprehensive dashboard card summarizing enterprise physical biometric terminal fleet
class ExternalHardwareFleetSummaryCard extends StatelessWidget {
  final ExternalHardwareFleetSummary summary;
  final VoidCallback? onManageFleet;

  const ExternalHardwareFleetSummaryCard({
    super.key,
    required this.summary,
    this.onManageFleet,
  });

  @override
  Widget build(BuildContext context) {
    final availability = summary.fleetAvailabilityPercent;
    final isHealthy = availability >= 95.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_rounded, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Biometric Hardware Fleet',
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
                    color: isHealthy
                        ? context.status.success.color.withValues(alpha: 0.12)
                        : context.status.warning.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${availability.toStringAsFixed(1)}% ONLINE',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isHealthy ? context.status.success.color : context.status.warning.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${summary.hikvisionMinMoeCount} Hikvision MinMoe • ${summary.zktecoAdmsCount} ZKTeco ADMS • ${summary.activeOnlineTerminals}/${summary.totalTerminals} Connected',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today Punches', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.totalDailyHardwarePunches}',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spoofs Blocked', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.antiSpoofAttacksBlocked}',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: context.status.danger.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avg Latency', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.averageHardwareLatencyMs.toStringAsFixed(0)}ms',
                        style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
