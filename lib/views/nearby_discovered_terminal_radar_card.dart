import 'package:flutter/material.dart';
import '../domain/models/nearby_discovered_terminal.dart';
import '../services/nearby_terminal_discovery_service.dart';

/// Card component visualizing physical terminals found in proximity with instant punch selector
class NearbyDiscoveredTerminalRadarCard extends StatefulWidget {
  final ValueChanged<NearbyDiscoveredTerminal>? onTerminalSelected;

  const NearbyDiscoveredTerminalRadarCard({
    super.key,
    this.onTerminalSelected,
  });

  @override
  State<NearbyDiscoveredTerminalRadarCard> createState() =>
      _NearbyDiscoveredTerminalRadarCardState();
}

class _NearbyDiscoveredTerminalRadarCardState
    extends State<NearbyDiscoveredTerminalRadarCard> {
  late final NearbyTerminalDiscoveryService _service;
  bool _isScanning = false;
  List<NearbyDiscoveredTerminal> _terminals = [];

  @override
  void initState() {
    super.initState();
    _service = NearbyTerminalDiscoveryService();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    final results = await _service.scanNearbyTerminals(subnetPrefix: '192.168.1');
    if (mounted) {
      setState(() {
        _isScanning = false;
        _terminals = results;
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
                    color: colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Machine Radar',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isScanning
                            ? 'Scanning local office network & BLE...'
                            : '${_terminals.length} physical terminal(s) detected in reach',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._terminals.map((term) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          term.discoveryMethod == 'BLE'
                              ? Icons.bluetooth_connected_rounded
                              : Icons.wifi_tethering_rounded,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                term.deviceName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${term.ipAddress} • ~${term.estimatedDistanceMeters}m away • ${term.discoveryMethod}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => widget.onTerminalSelected?.call(term),
                          child: const Text('Connect'),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
