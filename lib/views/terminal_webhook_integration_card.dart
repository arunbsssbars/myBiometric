import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/terminal_webhook_alert.dart';

/// Responsive Material 3 card displaying terminal incident webhook integration endpoints.
/// Built strictly following AQIL v2 responsive standards.
class TerminalWebhookIntegrationCard extends StatelessWidget {
  final TerminalWebhookEndpoint endpoint;
  final VoidCallback? onTestDispatch;

  const TerminalWebhookIntegrationCard({
    super.key,
    required this.endpoint,
    this.onTestDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final statusColor = endpoint.isEnabled ? context.status.success.color : context.colors.textSecondary;
    final statusLabel = endpoint.isEnabled ? 'WEBHOOK ACTIVE' : 'DISABLED';

    final severitiesList = endpoint.subscribedSeverities.map((s) => s.name.toUpperCase()).join(', ');
    final metaItems = <String>[
      endpoint.targetUrl,
      'Subscribed: $severitiesList',
      'HMAC-SHA256 Signed',
    ];
    final metaString = metaItems.join(' • ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: context.colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: context.colors.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.webhook_rounded,
                    color: statusColor,
                    size: AppSizes.iconMd,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        endpoint.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        metaString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    statusLabel,
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(color: context.colors.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Target URL: ${endpoint.targetUrl}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            if (onTestDispatch != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onTestDispatch,
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('Send Test Alert'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
