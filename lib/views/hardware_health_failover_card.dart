import 'package:flutter/material.dart';
import '../../domain/models/external_hardware_device.dart';
import '../../services/hardware_health_failover_service.dart';

class HardwareHealthFailoverCard extends StatelessWidget {
  final List<ExternalHardwareDevice> devices;
  final HardwareHealthFailoverService service;
  final String enterpriseId;
  final VoidCallback? onRefresh;

  const HardwareHealthFailoverCard({
    super.key,
    required this.devices,
    required this.service,
    required this.enterpriseId,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final resilience = service.calculateFleetResilience(enterpriseId);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined,
                          color: resilience > 80 ? Colors.green : Colors.orange),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Hardware Resilience & Failover',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${resilience.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: resilience > 80 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: resilience / 100.0,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  resilience > 80 ? Colors.green : Colors.orange,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Active Fleet Redundancy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (devices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No external biometric machines enrolled yet.'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: devices.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final dev = devices[index];
                  final isHealthy = dev.isHealthy;
                  final failoverDev = isHealthy
                      ? null
                      : service.resolveFailoverDevice(
                          failedDeviceId: dev.deviceId,
                          enterpriseId: enterpriseId,
                        );

                  return Row(
                    children: [
                      Icon(
                        isHealthy ? Icons.check_circle : Icons.error_outline,
                        color: isHealthy ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dev.deviceName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${dev.locationTag} • ${dev.ipAddress}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isHealthy && failoverDev != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Failover: ${failoverDev.deviceName}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
