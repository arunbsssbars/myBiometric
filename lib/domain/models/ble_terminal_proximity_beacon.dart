import 'package:flutter/foundation.dart';

/// Bluetooth Low Energy (BLE) proximity beacon data model for mobile-to-terminal punch
@immutable
class BleTerminalProximityBeacon {
  final String beaconUuid;
  final int major;
  final int minor;
  final String employeeId;
  final String enterpriseId;
  final int rssiThresholdDbm;
  final String encryptedPayload;
  final DateTime timestamp;

  const BleTerminalProximityBeacon({
    required this.beaconUuid,
    required this.major,
    required this.minor,
    required this.employeeId,
    required this.enterpriseId,
    this.rssiThresholdDbm = -75, // Default proximity ~1.5 meters
    required this.encryptedPayload,
    required this.timestamp,
  });

  bool isWithinProximity(int currentRssi) => currentRssi >= rssiThresholdDbm;

  Map<String, dynamic> toMap() => {
        'beaconUuid': beaconUuid,
        'major': major,
        'minor': minor,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'rssiThresholdDbm': rssiThresholdDbm,
        'encryptedPayload': encryptedPayload,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BleTerminalProximityBeacon.fromMap(Map<String, dynamic> map) =>
      BleTerminalProximityBeacon(
        beaconUuid: map['beaconUuid'] as String? ?? '',
        major: map['major'] as int? ?? 0,
        minor: map['minor'] as int? ?? 0,
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        rssiThresholdDbm: map['rssiThresholdDbm'] as int? ?? -75,
        encryptedPayload: map['encryptedPayload'] as String? ?? '',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
