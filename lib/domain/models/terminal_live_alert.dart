import 'package:flutter/material.dart';

/// Type of live alert emitted over the terminal's ISAPI / ADMS push notification stream.
enum TerminalAlertType {
  faceMatchSuccess,
  unknownFaceDetected,
  spoofingAttemptDetected,
  tamperAlarm,
  doorForcedOpen,
  doorHeldOpenTimeout,
  blackListMatch,
  duressAlarm,
  cardMatchSuccess,
  temperatureAbnormal,
}

/// Domain model representing a real-time event received over ISAPI `/ISAPI/Event/notification/alertStream`
/// or ADMS push socket connection.
class TerminalLiveAlert {
  final String alertId;
  final String deviceId;
  final String deviceName;
  final TerminalAlertType alertType;
  final String? employeeId;
  final String? employeeName;
  final double? similarityScore;
  final String? cardNo;
  final int doorIndex;
  final bool isDoorUnlocked;
  final String? snapshotBase64;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> rawDetails;

  const TerminalLiveAlert({
    required this.alertId,
    required this.deviceId,
    required this.deviceName,
    required this.alertType,
    this.employeeId,
    this.employeeName,
    this.similarityScore,
    this.cardNo,
    this.doorIndex = 1,
    this.isDoorUnlocked = false,
    this.snapshotBase64,
    required this.description,
    required this.timestamp,
    this.rawDetails = const {},
  });

  bool get isSecurityThreat {
    return alertType == TerminalAlertType.spoofingAttemptDetected ||
        alertType == TerminalAlertType.tamperAlarm ||
        alertType == TerminalAlertType.doorForcedOpen ||
        alertType == TerminalAlertType.blackListMatch ||
        alertType == TerminalAlertType.duressAlarm;
  }

  Color get alertColor {
    switch (alertType) {
      case TerminalAlertType.faceMatchSuccess:
      case TerminalAlertType.cardMatchSuccess:
        return const Color(0xFF10B981); // Emerald Green
      case TerminalAlertType.unknownFaceDetected:
      case TerminalAlertType.doorHeldOpenTimeout:
      case TerminalAlertType.temperatureAbnormal:
        return const Color(0xFFF59E0B); // Amber
      case TerminalAlertType.spoofingAttemptDetected:
      case TerminalAlertType.tamperAlarm:
      case TerminalAlertType.doorForcedOpen:
      case TerminalAlertType.blackListMatch:
      case TerminalAlertType.duressAlarm:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get alertIcon {
    switch (alertType) {
      case TerminalAlertType.faceMatchSuccess:
        return Icons.face_retouching_natural_rounded;
      case TerminalAlertType.cardMatchSuccess:
        return Icons.credit_card_rounded;
      case TerminalAlertType.unknownFaceDetected:
        return Icons.help_outline_rounded;
      case TerminalAlertType.spoofingAttemptDetected:
        return Icons.masks_rounded;
      case TerminalAlertType.tamperAlarm:
        return Icons.warning_amber_rounded;
      case TerminalAlertType.doorForcedOpen:
        return Icons.sensor_door_outlined;
      case TerminalAlertType.doorHeldOpenTimeout:
        return Icons.timer_outlined;
      case TerminalAlertType.blackListMatch:
        return Icons.person_off_rounded;
      case TerminalAlertType.duressAlarm:
        return Icons.emergency_share_rounded;
      case TerminalAlertType.temperatureAbnormal:
        return Icons.thermostat_rounded;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'alertType': alertType.name,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'similarityScore': similarityScore,
      'cardNo': cardNo,
      'doorIndex': doorIndex,
      'isDoorUnlocked': isDoorUnlocked,
      'snapshotBase64': snapshotBase64,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'rawDetails': rawDetails,
    };
  }

  factory TerminalLiveAlert.fromJson(Map<String, dynamic> json) {
    TerminalAlertType parseType(String? name) {
      return TerminalAlertType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => TerminalAlertType.faceMatchSuccess,
      );
    }

    return TerminalLiveAlert(
      alertId: json['alertId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Terminal',
      alertType: parseType(json['alertType'] as String?),
      employeeId: json['employeeId'] as String?,
      employeeName: json['employeeName'] as String?,
      similarityScore: (json['similarityScore'] as num?)?.toDouble(),
      cardNo: json['cardNo'] as String?,
      doorIndex: (json['doorIndex'] as num?)?.toInt() ?? 1,
      isDoorUnlocked: json['isDoorUnlocked'] as bool? ?? false,
      snapshotBase64: json['snapshotBase64'] as String?,
      description: json['description'] as String? ?? 'Terminal alert received',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      rawDetails: (json['rawDetails'] as Map<String, dynamic>?) ?? {},
    );
  }
}
