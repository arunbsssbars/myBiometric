import 'package:flutter/foundation.dart';

enum DeviceHealthState {
  healthy,
  warning,
  critical,
  offline,
}

/// Incident or failure reported during hardware watchdog monitoring
@immutable
class TerminalWatchdogIncident {
  final String incidentId;
  final String deviceId;
  final String category; // 'CAMERA_FAULT', 'MEMORY_LEAK', 'STORAGE_EXHAUSTION', 'TIME_DRIFT'
  final String message;
  final DateTime detectedAt;
  final bool autoRemediated;
  final String? remediationAction; // 'REBOOT_SERVICE', 'PURGE_CACHE', 'NTP_RESYNC'

  const TerminalWatchdogIncident({
    required this.incidentId,
    required this.deviceId,
    required this.category,
    required this.message,
    required this.detectedAt,
    this.autoRemediated = false,
    this.remediationAction,
  });

  Map<String, dynamic> toMap() => {
        'incidentId': incidentId,
        'deviceId': deviceId,
        'category': category,
        'message': message,
        'detectedAt': detectedAt.toIso8601String(),
        'autoRemediated': autoRemediated,
        'remediationAction': remediationAction,
      };

  factory TerminalWatchdogIncident.fromMap(Map<String, dynamic> map) =>
      TerminalWatchdogIncident(
        incidentId: map['incidentId'] as String? ?? '',
        deviceId: map['deviceId'] as String? ?? '',
        category: map['category'] as String? ?? 'UNKNOWN',
        message: map['message'] as String? ?? '',
        detectedAt: map['detectedAt'] != null
            ? DateTime.tryParse(map['detectedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        autoRemediated: map['autoRemediated'] as bool? ?? false,
        remediationAction: map['remediationAction'] as String?,
      );
}

/// Real-time health metrics captured by the kiosk watchdog daemon
@immutable
class TerminalWatchdogMetrics {
  final String deviceId;
  final double cpuUsagePercent;
  final double ramUsagePercent;
  final double diskFreeMb;
  final int consecutiveCameraFailures;
  final int ntpDriftMillis;
  final DateTime capturedAt;

  const TerminalWatchdogMetrics({
    required this.deviceId,
    required this.cpuUsagePercent,
    required this.ramUsagePercent,
    required this.diskFreeMb,
    required this.consecutiveCameraFailures,
    required this.ntpDriftMillis,
    required this.capturedAt,
  });

  DeviceHealthState get overallState {
    if (consecutiveCameraFailures >= 5 || diskFreeMb < 50 || ntpDriftMillis.abs() > 30000) {
      return DeviceHealthState.critical;
    }
    if (cpuUsagePercent > 85 || ramUsagePercent > 90 || consecutiveCameraFailures >= 2) {
      return DeviceHealthState.warning;
    }
    return DeviceHealthState.healthy;
  }
}
