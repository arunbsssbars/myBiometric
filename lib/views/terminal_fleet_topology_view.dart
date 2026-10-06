import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';

/// AQIL-hardened widget presenting enterprise-wide multi-terminal fleet status and branch topology.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalFleetTopologyView extends StatelessWidget {
  final List<BiometricTerminalDevice> devices;
  final int activeAlarmsCount;
  final VoidCallback? onSyncAll;
  final ValueChanged<BiometricTerminalDevice>? onTestDevice;
  final ValueChanged<BiometricTerminalDevice>? onSyncDevice;

  const TerminalFleetTopologyView({
    super.key,
    required this.devices,
    this.activeAlarmsCount = 0,
    this.onSyncAll,
    this.onTestDevice,
    this.onSyncDevice,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    final totalDevices = devices.length;
    final onlineCount = devices.where((d) => d.status == DeviceConnectionStatus.online).length;
    final totalPunchesSynced = devices.fold<int>(0, (sum, d) => sum + d.totalEventsSynced);

    // Group devices by Branch
    final Map<String, List<BiometricTerminalDevice>> branchGroups = {};
    for (final device in devices) {
      final branch = (device.branchName != null && device.branchName!.trim().isNotEmpty)
          ? device.branchName!.trim()
          : 'General Headquarters';
      branchGroups.putIfAbsent(branch, () => []).add(device);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Status Bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Online Fleet',
                  value: '$onlineCount / $totalDevices',
                  color: statusTheme.success.color,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: colors.outlineVariant.withValues(alpha: 0.3)),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Punches Synced',
                  value: totalPunchesSynced.toString(),
                  color: colors.primary,
                  icon: Icons.sync_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: colors.outlineVariant.withValues(alpha: 0.3)),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Security Alerts',
                  value: activeAlarmsCount.toString(),
                  color: activeAlarmsCount > 0 ? statusTheme.danger.color : colors.onSurfaceVariant,
                  icon: activeAlarmsCount > 0 ? Icons.warning_amber_rounded : Icons.shield_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Branch Topology Tree
        ...branchGroups.entries.map((entry) {
          final branchName = entry.key;
          final branchDevices = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.business_rounded, color: colors.onSurfaceVariant, size: AppSizes.iconSm),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        branchName,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '${branchDevices.length} Machines',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                const SizedBox(height: AppSpacing.sm),

                // Device Items inside branch
                ...branchDevices.map((d) {
                  final isOnline = d.status == DeviceConnectionStatus.online;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? statusTheme.success.color : statusTheme.danger.color,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name,
                                style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${d.modelName} • ${d.ipAddress}:${d.port}',
                                style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (onTestDevice != null)
                          IconButton(
                            icon: Icon(Icons.wifi_tethering_rounded, size: AppSizes.iconSm, color: colors.primary),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: 'Test Connection',
                            onPressed: () => onTestDevice!(d),
                          ),
                        if (onSyncDevice != null)
                          IconButton(
                            icon: Icon(Icons.sync_rounded, size: AppSizes.iconSm, color: statusTheme.success.color),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            tooltip: 'Sync Logs',
                            onPressed: () => onSyncDevice!(d),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final textTheme = context.text;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Column(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
