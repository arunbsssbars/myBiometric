import 'package:flutter/material.dart';
import '../domain/models/ble_terminal_proximity_beacon.dart';
import '../services/ble_terminal_proximity_service.dart';

/// Card component presenting BLE proximity broadcasting state for punch at physical terminal
class BleTerminalProximityCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;
  final VoidCallback? onPunchTriggered;

  const BleTerminalProximityCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
    this.onPunchTriggered,
  });

  @override
  State<BleTerminalProximityCard> createState() => _BleTerminalProximityCardState();
}

class _BleTerminalProximityCardState extends State<BleTerminalProximityCard>
    with SingleTickerProviderStateMixin {
  late final BleTerminalProximityService _service;
  late AnimationController _pulseController;
  bool _isBroadcasting = false;
  BleTerminalProximityBeacon? _activeBeacon;

  @override
  void initState() {
    super.initState();
    _service = BleTerminalProximityService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleBroadcasting() {
    setState(() {
      _isBroadcasting = !_isBroadcasting;
      if (_isBroadcasting) {
        _activeBeacon = _service.generateBeacon(
          employeeId: widget.employeeId,
          enterpriseId: widget.enterpriseId,
        );
      } else {
        _activeBeacon = null;
      }
    });
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
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _isBroadcasting ? 1.0 + (_pulseController.value * 0.15) : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isBroadcasting
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                        ),
                        child: Icon(
                          Icons.bluetooth_audio_rounded,
                          color: _isBroadcasting
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BLE Terminal Punch',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isBroadcasting
                            ? 'Broadcasting to nearby terminal (< 1.5m)'
                            : 'Stand near machine and tap Broadcast',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isBroadcasting,
                  onChanged: (val) => _toggleBroadcasting(),
                ),
              ],
            ),
            if (_isBroadcasting && _activeBeacon != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_tethering_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Signal: ${_activeBeacon!.encryptedPayload} • Threshold: ${_activeBeacon!.rssiThresholdDbm} dBm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
