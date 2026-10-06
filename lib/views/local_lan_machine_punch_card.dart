import 'package:flutter/material.dart';
import '../domain/models/local_lan_machine_punch_request.dart';
import '../services/local_lan_machine_punch_service.dart';

/// Card component for initiating a direct Local Wi-Fi LAN punch to physical terminal
class LocalLanMachinePunchCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;
  final String defaultTerminalIp;

  const LocalLanMachinePunchCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
    this.defaultTerminalIp = '192.168.1.120',
  });

  @override
  State<LocalLanMachinePunchCard> createState() => _LocalLanMachinePunchCardState();
}

class _LocalLanMachinePunchCardState extends State<LocalLanMachinePunchCard> {
  late final LocalLanMachinePunchService _service;
  bool _isDispatching = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _service = LocalLanMachinePunchService();
  }

  Future<void> _punch(String type) async {
    setState(() {
      _isDispatching = true;
      _statusMessage = null;
    });

    final req = LocalLanMachinePunchRequest(
      terminalIp: widget.defaultTerminalIp,
      employeeId: widget.employeeId,
      enterpriseId: widget.enterpriseId,
      punchType: type,
      punchTime: DateTime.now(),
    );

    final success = await _service.dispatchLanPunch(request: req);

    if (mounted) {
      setState(() {
        _isDispatching = false;
        _statusMessage = success
            ? 'Success: Direct LAN punch sent to ${widget.defaultTerminalIp}'
            : 'Error: Terminal unreachable on local Wi-Fi';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.tertiaryContainer,
                  ),
                  child: Icon(
                    Icons.lan_rounded,
                    color: colorScheme.tertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct LAN Wi-Fi Punch',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Target Terminal: ${widget.defaultTerminalIp}',
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
                  child: FilledButton.tonalIcon(
                    onPressed: _isDispatching ? null : () => _punch('PUNCH_IN'),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Punch IN'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDispatching ? null : () => _punch('PUNCH_OUT'),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Punch OUT'),
                  ),
                ),
              ],
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _statusMessage!.startsWith('Success')
                      ? colorScheme.primary
                      : colorScheme.error,
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
