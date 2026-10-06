import 'package:flutter/foundation.dart';

/// Model representing a geofenced remote relay trigger on a physical biometric machine
@immutable
class MobileTerminalRelayPunch {
  final String relayId;
  final String terminalId;
  final String employeeId;
  final String enterpriseId;
  final double userLatitude;
  final double userLongitude;
  final double terminalLatitude;
  final double terminalLongitude;
  final int maxAllowedDistanceMeters;
  final bool biometricVerifiedOnPhone;
  final DateTime timestamp;

  const MobileTerminalRelayPunch({
    required this.relayId,
    required this.terminalId,
    required this.employeeId,
    required this.enterpriseId,
    required this.userLatitude,
    required this.userLongitude,
    required this.terminalLatitude,
    required this.terminalLongitude,
    this.maxAllowedDistanceMeters = 50, // Must be within 50 meters of machine
    required this.biometricVerifiedOnPhone,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'relayId': relayId,
        'terminalId': terminalId,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'userLatitude': userLatitude,
        'userLongitude': userLongitude,
        'terminalLatitude': terminalLatitude,
        'terminalLongitude': terminalLongitude,
        'maxAllowedDistanceMeters': maxAllowedDistanceMeters,
        'biometricVerifiedOnPhone': biometricVerifiedOnPhone,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MobileTerminalRelayPunch.fromMap(Map<String, dynamic> map) =>
      MobileTerminalRelayPunch(
        relayId: map['relayId'] as String? ?? '',
        terminalId: map['terminalId'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        userLatitude: (map['userLatitude'] as num?)?.toDouble() ?? 0.0,
        userLongitude: (map['userLongitude'] as num?)?.toDouble() ?? 0.0,
        terminalLatitude: (map['terminalLatitude'] as num?)?.toDouble() ?? 0.0,
        terminalLongitude: (map['terminalLongitude'] as num?)?.toDouble() ?? 0.0,
        maxAllowedDistanceMeters: map['maxAllowedDistanceMeters'] as int? ?? 50,
        biometricVerifiedOnPhone: map['biometricVerifiedOnPhone'] as bool? ?? false,
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
