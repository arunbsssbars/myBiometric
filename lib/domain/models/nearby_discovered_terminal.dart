import 'package:flutter/foundation.dart';

/// Represents a physical attendance terminal discovered nearby by the mobile phone
@immutable
class NearbyDiscoveredTerminal {
  final String terminalId;
  final String deviceName;
  final String ipAddress;
  final int port;
  final String discoveryMethod; // 'BLE', 'MDNS', 'SSDP', 'WIFI_SSID'
  final int signalStrengthDbm; // RSSI or Wi-Fi dBm (-40 = excellent, -90 = weak)
  final double estimatedDistanceMeters;
  final bool isReadyForDirectPunch;
  final DateTime lastSeen;

  const NearbyDiscoveredTerminal({
    required this.terminalId,
    required this.deviceName,
    required this.ipAddress,
    this.port = 80,
    required this.discoveryMethod,
    this.signalStrengthDbm = -65,
    this.estimatedDistanceMeters = 1.5,
    this.isReadyForDirectPunch = true,
    required this.lastSeen,
  });

  bool get isProximityImmediate => estimatedDistanceMeters <= 2.0;

  Map<String, dynamic> toMap() => {
        'terminalId': terminalId,
        'deviceName': deviceName,
        'ipAddress': ipAddress,
        'port': port,
        'discoveryMethod': discoveryMethod,
        'signalStrengthDbm': signalStrengthDbm,
        'estimatedDistanceMeters': estimatedDistanceMeters,
        'isReadyForDirectPunch': isReadyForDirectPunch,
        'lastSeen': lastSeen.toIso8601String(),
      };

  factory NearbyDiscoveredTerminal.fromMap(Map<String, dynamic> map) =>
      NearbyDiscoveredTerminal(
        terminalId: map['terminalId'] as String? ?? '',
        deviceName: map['deviceName'] as String? ?? 'Biometric Terminal',
        ipAddress: map['ipAddress'] as String? ?? '192.168.1.100',
        port: map['port'] as int? ?? 80,
        discoveryMethod: map['discoveryMethod'] as String? ?? 'MDNS',
        signalStrengthDbm: map['signalStrengthDbm'] as int? ?? -65,
        estimatedDistanceMeters: (map['estimatedDistanceMeters'] as num?)?.toDouble() ?? 1.5,
        isReadyForDirectPunch: map['isReadyForDirectPunch'] as bool? ?? true,
        lastSeen: map['lastSeen'] != null
            ? DateTime.tryParse(map['lastSeen'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
