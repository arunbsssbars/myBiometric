import 'package:flutter/material.dart';
import 'external_biometric_device.dart';

/// Health assessment grade for an external biometric hardware terminal.
enum TerminalHealthGrade {
  excellent,
  good,
  warning,
  critical,
  offline,
}

/// Comprehensive health and connectivity diagnostic report for a physical biometric machine.
class TerminalDiagnosticReport {
  final String deviceId;
  final String deviceName;
  final String ipAddress;
  final int port;
  final TerminalProtocol protocol;
  final bool isReachable;
  final int latencyMs;
  final String? firmwareVersion;
  final String? serialNumber;
  final double storageUsagePercent; // 0.0 - 100.0
  final int timeDriftSeconds; // Difference between machine clock and server time
  final int healthScore; // 0 - 100
  final String statusSummary;
  final DateTime checkedAt;
  final Map<String, dynamic> diagnosticDetails;

  const TerminalDiagnosticReport({
    required this.deviceId,
    required this.deviceName,
    required this.ipAddress,
    required this.port,
    required this.protocol,
    required this.isReachable,
    required this.latencyMs,
    this.firmwareVersion,
    this.serialNumber,
    this.storageUsagePercent = 0.0,
    this.timeDriftSeconds = 0,
    required this.healthScore,
    required this.statusSummary,
    required this.checkedAt,
    this.diagnosticDetails = const {},
  });

  TerminalHealthGrade get healthGrade {
    if (!isReachable) return TerminalHealthGrade.offline;
    if (healthScore >= 90) return TerminalHealthGrade.excellent;
    if (healthScore >= 75) return TerminalHealthGrade.good;
    if (healthScore >= 50) return TerminalHealthGrade.warning;
    return TerminalHealthGrade.critical;
  }

  String get healthGradeLabel {
    switch (healthGrade) {
      case TerminalHealthGrade.excellent:
        return 'EXCELLENT';
      case TerminalHealthGrade.good:
        return 'GOOD';
      case TerminalHealthGrade.warning:
        return 'DEGRADED';
      case TerminalHealthGrade.critical:
        return 'CRITICAL';
      case TerminalHealthGrade.offline:
        return 'OFFLINE';
    }
  }

  Color get healthColor {
    switch (healthGrade) {
      case TerminalHealthGrade.excellent:
        return const Color(0xFF10B981); // Emerald Green
      case TerminalHealthGrade.good:
        return const Color(0xFF0EA5E9); // Sky Blue
      case TerminalHealthGrade.warning:
        return const Color(0xFFF59E0B); // Amber
      case TerminalHealthGrade.critical:
        return const Color(0xFFEF4444); // Red
      case TerminalHealthGrade.offline:
        return const Color(0xFF64748B); // Slate Grey
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'port': port,
      'protocol': protocol.name,
      'isReachable': isReachable,
      'latencyMs': latencyMs,
      'firmwareVersion': firmwareVersion,
      'serialNumber': serialNumber,
      'storageUsagePercent': storageUsagePercent,
      'timeDriftSeconds': timeDriftSeconds,
      'healthScore': healthScore,
      'statusSummary': statusSummary,
      'checkedAt': checkedAt.toIso8601String(),
      'diagnosticDetails': diagnosticDetails,
    };
  }

  factory TerminalDiagnosticReport.fromJson(Map<String, dynamic> json) {
    TerminalProtocol parseProtocol(String? name) {
      return TerminalProtocol.values.firstWhere(
        (p) => p.name == name,
        orElse: () => TerminalProtocol.hikvisionIsapi,
      );
    }

    return TerminalDiagnosticReport(
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Terminal',
      ipAddress: json['ipAddress'] as String? ?? '127.0.0.1',
      port: (json['port'] as num?)?.toInt() ?? 80,
      protocol: parseProtocol(json['protocol'] as String?),
      isReachable: json['isReachable'] as bool? ?? false,
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
      firmwareVersion: json['firmwareVersion'] as String?,
      serialNumber: json['serialNumber'] as String?,
      storageUsagePercent: (json['storageUsagePercent'] as num?)?.toDouble() ?? 0.0,
      timeDriftSeconds: (json['timeDriftSeconds'] as num?)?.toInt() ?? 0,
      healthScore: (json['healthScore'] as num?)?.toInt() ?? 0,
      statusSummary: json['statusSummary'] as String? ?? 'Unknown',
      checkedAt: json['checkedAt'] != null
          ? DateTime.tryParse(json['checkedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      diagnosticDetails: (json['diagnosticDetails'] as Map<String, dynamic>?) ?? {},
    );
  }
}
