import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/minmoe_remote_relay_command.dart';

/// Card presenting remote door control actions for Hikvision MinMoe terminals
class MinMoeRemoteRelayCard extends StatelessWidget {
  final String terminalId;
  final ValueChanged<MinMoeRelayAction>? onExecuteAction;

  const MinMoeRemoteRelayCard({
    super.key,
    required this.terminalId,
    this.onExecuteAction,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.meeting_room_outlined, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Remote Access & Door Relay',
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
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'DOOR #1',
                    style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Terminal: $terminalId • Real-time electric door strike & electromagnetic lock actuation',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.status.success.color,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onExecuteAction != null
                        ? () => onExecuteAction!(MinMoeRelayAction.openDoor)
                        : null,
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text('Unlock Door'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.status.danger.color,
                      side: BorderSide(color: context.status.danger.color.withValues(alpha: 0.5)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onExecuteAction != null
                        ? () => onExecuteAction!(MinMoeRelayAction.triggerDuressAlarm)
                        : null,
                    icon: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: const Text('Trigger Alarm'),
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
