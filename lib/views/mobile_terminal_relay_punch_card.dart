import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/mobile_terminal_relay_punch.dart';
import '../services/mobile_terminal_relay_punch_service.dart';

/// Card component allowing geofenced remote unlock and attendance punch via machine relay
class MobileTerminalRelayPunchCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;
  final String terminalId;
  final double terminalLat;
  final double terminalLng;

  const MobileTerminalRelayPunchCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
    required this.terminalId,
    this.terminalLat = 12.9716,
    this.terminalLng = 77.5946,
  });

  @override
  State<MobileTerminalRelayPunchCard> createState() => _MobileTerminalRelayPunchCardState();
}

class _MobileTerminalRelayPunchCardState extends State<MobileTerminalRelayPunchCard> {
  late final MobileTerminalRelayPunchService _service;
  bool _isTriggering = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _service = MobileTerminalRelayPunchService();
  }

  Future<void> _handleRemoteUnlock() async {
    setState(() {
      _isTriggering = true;
      _statusText = null;
    });

    // Simulating phone GPS at 5 meters from terminal
    final punch = MobileTerminalRelayPunch(
      relayId: 'RELAY_${DateTime.now().millisecondsSinceEpoch}',
      terminalId: widget.terminalId,
      employeeId: widget.employeeId,
      enterpriseId: widget.enterpriseId,
      userLatitude: widget.terminalLat + 0.00003,
      userLongitude: widget.terminalLng + 0.00003,
      terminalLatitude: widget.terminalLat,
      terminalLongitude: widget.terminalLng,
      biometricVerifiedOnPhone: true,
      timestamp: DateTime.now(),
    );

    final success = await _service.triggerTerminalDoorRelay(punch);

    if (mounted) {
      setState(() {
        _isTriggering = false;
        _statusText = success
            ? 'Access Granted: Relay strike sent to machine'
            : 'Access Denied: Beyond allowed distance (< 50m)';
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
                    color: colorScheme.errorContainer.withValues(alpha: 0.7),
                  ),
                  child: Icon(
                    Icons.door_sliding_outlined,
                    color: colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Machine Door Relay Punch',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Unlock turnstile & record attendance',
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isTriggering ? null : _handleRemoteUnlock,
                icon: _isTriggering
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.onPrimary),
                      )
                    : const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Unlock Door & Punch In'),
              ),
            ),
            if (_statusText != null) ...[
              const SizedBox(height: 10),
              Text(
                _statusText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _statusText!.startsWith('Access Granted')
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
