import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/zkteco_machine_command.dart';

/// Card presenting queued and executed ZKTeco ADMS machine commands
class ZktecoCommandQueueCard extends StatelessWidget {
  final List<ZktecoMachineCommand> commands;
  final ValueChanged<String>? onQueueQuickCommand;

  const ZktecoCommandQueueCard({
    super.key,
    required this.commands,
    this.onQueueQuickCommand,
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
                Icon(Icons.terminal_rounded, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'ZKTeco Command Queue',
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
                    '${commands.length} QUEUED',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Buffered ADMS commands dispatched on next GET /iclock/getrequest polling cycle',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: Text('REBOOT', style: context.text.labelSmall),
                  onPressed: onQueueQuickCommand != null ? () => onQueueQuickCommand!('REBOOT') : null,
                ),
                ActionChip(
                  label: Text('CHECK LOG', style: context.text.labelSmall),
                  onPressed: onQueueQuickCommand != null ? () => onQueueQuickCommand!('CHECK') : null,
                ),
                ActionChip(
                  label: Text('CLEAR LOG', style: context.text.labelSmall),
                  onPressed: onQueueQuickCommand != null ? () => onQueueQuickCommand!('CLEAR LOG') : null,
                ),
                ActionChip(
                  label: Text('DEVICE INFO', style: context.text.labelSmall),
                  onPressed: onQueueQuickCommand != null ? () => onQueueQuickCommand!('INFO') : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
