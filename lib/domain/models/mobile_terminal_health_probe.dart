import 'package:flutter/foundation.dart';

/// Configuration for physical biometric terminal hardware health monitoring on mobile
@immutable
class MobileTerminalHealthProbe {
  final String terminalId;
  final String ipAddress;
  final bool isOnline;
  final int latencyMs;
  final double cameraFps;
  final double diskSpacePercent;
  final String firmwareVersion;
  final DateTime probedAt;

  const MobileTerminalHealthProbe({
    required this.terminalId,
    required this.ipAddress,
    required this.isOnline,
    required this.latencyMs,
    this.cameraFps = 25.0,
    this.diskSpacePercent = 42.0,
    this.firmwareVersion = 'V5.1.8_build240915',
    required this.probedAt,
  });

  bool get isOperational => isOnline && latencyMs < 500 && cameraFps >= 15.0;

  Map<String, dynamic> toMap() => {
        'terminalId': terminalId,
        'ipAddress': ipAddress,
        'isOnline': isOnline,
        'latencyMs': latencyMs,
        'cameraFps': cameraFps,
        'diskSpacePercent': diskSpacePercent,
        'firmwareVersion': firmwareVersion,
        'probedAt': probedAt.toIso8601String(),
      };

  factory MobileTerminalHealthProbe.fromMap(Map<String, dynamic> map) =>
      MobileTerminalHealthProbe(
        terminalId: map['terminalId'] as String? ?? '',
        ipAddress: map['ipAddress'] as String? ?? '',
        isOnline: map['isOnline'] as bool? ?? false,
        latencyMs: map['latencyMs'] as int? ?? 999,
        cameraFps: (map['cameraFps'] as num?)?.toDouble() ?? 0.0,
        diskSpacePercent: (map['diskSpacePercent'] as num?)?.toDouble() ?? 0.0,
        firmwareVersion: map['firmwareVersion'] as String? ?? '',
        probedAt: map['probedAt'] != null
            ? DateTime.tryParse(map['probedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
