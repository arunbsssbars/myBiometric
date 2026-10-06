import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../services/mobile_terminal_sync_drain_service.dart';

/// Card component visualizing offline punch buffer and sync-to-terminal status
class MobileTerminalSyncDrainCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;
  final String terminalIp;

  const MobileTerminalSyncDrainCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
    this.terminalIp = '192.168.1.120',
  });

  @override
  State<MobileTerminalSyncDrainCard> createState() => _MobileTerminalSyncDrainCardState();
}

class _MobileTerminalSyncDrainCardState extends State<MobileTerminalSyncDrainCard> {
  late final MobileTerminalSyncDrainService _service;
  bool _isDraining = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _service = MobileTerminalSyncDrainService();
  }

  void _recordOfflinePunch() {
    setState(() {
      _service.enqueuePunch(
        employeeId: widget.employeeId,
        enterpriseId: widget.enterpriseId,
        punchType: 'PUNCH_IN',
      );
      _statusText = 'Recorded offline. Queued for terminal sync.';
    });
  }

  Future<void> _drainQueue() async {
    setState(() => _isDraining = true);
    final count = await _service.drainToTerminal(terminalIp: widget.terminalIp);
    if (mounted) {
      setState(() {
        _isDraining = false;
        _statusText = count > 0
            ? 'Successfully synced $count punches to ${widget.terminalIp}'
            : 'No punches in queue to drain';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final queueCount = _service.queuedPunches.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Badge(
                  label: Text('$queueCount'),
                  isLabelVisible: queueCount > 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      Icons.sync_problem_rounded,
                      color: queueCount > 0 ? colorScheme.error : colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Machine Queue',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        queueCount > 0
                            ? '$queueCount pending punch(es) stored locally'
                            : 'All punches synced with physical terminal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _recordOfflinePunch,
                    child: const Text('+ Offline Punch'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_isDraining || queueCount == 0) ? null : _drainQueue,
                    icon: _isDraining
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.onPrimary),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Drain to Machine'),
                  ),
                ),
              ],
            ),
            if (_statusText != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
