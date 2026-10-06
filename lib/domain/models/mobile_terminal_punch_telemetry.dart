import 'package:flutter/foundation.dart';

/// Comprehensive telemetry log captured during a mobile-to-machine punch attempt
@immutable
class MobileTerminalPunchTelemetry {
  final String telemetryId;
  final String terminalId;
  final String employeeId;
  final String channelUsed;
  final int handshakeDurationMs;
  final int totalLatencyMs;
  final int signalRssiDbm;
  final bool success;
  final String? failureReason;
  final DateTime recordedAt;

  const MobileTerminalPunchTelemetry({
    required this.telemetryId,
    required this.terminalId,
    required this.employeeId,
    required this.channelUsed,
    required this.handshakeDurationMs,
    required this.totalLatencyMs,
    required this.signalRssiDbm,
    required this.success,
    this.failureReason,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() => {
        'telemetryId': telemetryId,
        'terminalId': terminalId,
        'employeeId': employeeId,
        'channelUsed': channelUsed,
        'handshakeDurationMs': handshakeDurationMs,
        'totalLatencyMs': totalLatencyMs,
        'signalRssiDbm': signalRssiDbm,
        'success': success,
        'failureReason': failureReason,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory MobileTerminalPunchTelemetry.fromMap(Map<String, dynamic> map) =>
      MobileTerminalPunchTelemetry(
        telemetryId: map['telemetryId'] as String? ?? '',
        terminalId: map['terminalId'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        channelUsed: map['channelUsed'] as String? ?? 'BLE',
        handshakeDurationMs: map['handshakeDurationMs'] as int? ?? 0,
        totalLatencyMs: map['totalLatencyMs'] as int? ?? 0,
        signalRssiDbm: map['signalRssiDbm'] as int? ?? -60,
        success: map['success'] as bool? ?? true,
        failureReason: map['failureReason'] as String?,
        recordedAt: map['recordedAt'] != null
            ? DateTime.tryParse(map['recordedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
