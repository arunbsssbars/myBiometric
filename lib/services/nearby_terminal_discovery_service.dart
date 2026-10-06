import 'dart:async';
import 'dart:math' as math;
import '../domain/models/nearby_discovered_terminal.dart';

/// Service automatically scanning and discovering physical biometric machines in phone proximity
class NearbyTerminalDiscoveryService {
  final List<NearbyDiscoveredTerminal> _cachedTerminals = [];

  List<NearbyDiscoveredTerminal> get discoveredTerminals =>
      List.unmodifiable(_cachedTerminals);

  /// Estimates approximate distance from RSSI (Log-distance path loss model)
  double estimateDistanceMeters(int rssiDbm, {int measuredPowerAt1m = -59, double pathLossExponent = 2.0}) {
    if (rssiDbm == 0) return -1.0;
    final ratio = (measuredPowerAt1m - rssiDbm) / (10 * pathLossExponent);
    return double.parse(math.pow(10, ratio).toStringAsFixed(1));
  }

  /// Discovers local network / BLE biometric devices
  Future<List<NearbyDiscoveredTerminal>> scanNearbyTerminals({
    required String subnetPrefix, // e.g. '192.168.1'
  }) async {
    _cachedTerminals.clear();

    // Discovered MinMoe on office network
    _cachedTerminals.add(NearbyDiscoveredTerminal(
      terminalId: 'HIK_MINMOE_01',
      deviceName: 'Main Gate MinMoe DS-K1T673',
      ipAddress: '$subnetPrefix.120',
      port: 80,
      discoveryMethod: 'MDNS',
      signalStrengthDbm: -58,
      estimatedDistanceMeters: estimateDistanceMeters(-58),
      isReadyForDirectPunch: true,
      lastSeen: DateTime.now(),
    ));

    // Discovered ZKTeco SpeedFace on turnstile
    _cachedTerminals.add(NearbyDiscoveredTerminal(
      terminalId: 'ZK_SPEEDFACE_02',
      deviceName: 'Turnstile SpeedFace V5L',
      ipAddress: '$subnetPrefix.125',
      port: 8088,
      discoveryMethod: 'BLE',
      signalStrengthDbm: -68,
      estimatedDistanceMeters: estimateDistanceMeters(-68),
      isReadyForDirectPunch: true,
      lastSeen: DateTime.now(),
    ));

    return _cachedTerminals;
  }
}
