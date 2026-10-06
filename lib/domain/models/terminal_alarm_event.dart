import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/app_format_utils.dart';

/// Severity level of a terminal security or hardware alarm.
enum TerminalAlarmSeverity {
  critical,
  high,
  medium,
  low,
}

/// Category of external hardware terminal alarm.
enum TerminalAlarmType {
  doorForcedOpen,
  deviceTamper,
  antiPassbackBreach,
  unauthorizedFace,
  blacklistDetected,
  multipleAuthFailures,
  faceMaskMissing,
  duressPinTriggered,
  deviceOffline,
}

/// Domain model representing a security alert or hardware alarm reported by an external biometric terminal.
class TerminalAlarmEvent {
  final String id;
  final String deviceId;
  final String enterpriseId;
  final String terminalName;
  final TerminalAlarmType type;
  final TerminalAlarmSeverity severity;
  final DateTime timestamp;
  final String details;
  final String? employeeId;
  final String? employeeName;
  final String? snapshotUrl;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  const TerminalAlarmEvent({
    required this.id,
    required this.deviceId,
    required this.enterpriseId,
    required this.terminalName,
    required this.type,
    this.severity = TerminalAlarmSeverity.high,
    required this.timestamp,
    required this.details,
    this.employeeId,
    this.employeeName,
    this.snapshotUrl,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
  });

  String get typeDisplayName {
    switch (type) {
      case TerminalAlarmType.doorForcedOpen:
        return 'Door Forced Open / Intrusion';
      case TerminalAlarmType.deviceTamper:
        return 'Hardware Tamper Alarm';
      case TerminalAlarmType.antiPassbackBreach:
        return 'Anti-Passback Violation (Tailgating)';
      case TerminalAlarmType.unauthorizedFace:
        return 'Unauthorized Face Scan';
      case TerminalAlarmType.blacklistDetected:
        return 'Restricted Person Alert';
      case TerminalAlarmType.multipleAuthFailures:
        return 'Consecutive Auth Failures';
      case TerminalAlarmType.faceMaskMissing:
        return 'Face Mask Missing';
      case TerminalAlarmType.duressPinTriggered:
        return 'Duress PIN Triggered (Emergency)';
      case TerminalAlarmType.deviceOffline:
        return 'Terminal Offline Alert';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'enterpriseId': enterpriseId,
      'terminalName': terminalName,
      'type': type.name,
      'severity': severity.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
      if (employeeId != null) 'employeeId': employeeId,
      if (employeeName != null) 'employeeName': employeeName,
      if (snapshotUrl != null) 'snapshotUrl': snapshotUrl,
      'isAcknowledged': isAcknowledged,
      if (acknowledgedBy != null) 'acknowledgedBy': acknowledgedBy,
      'acknowledgedAt': acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
    };
  }

  factory TerminalAlarmEvent.fromMap(Map<String, dynamic> map, {required String id}) {
    return TerminalAlarmEvent(
      id: id,
      deviceId: (map['deviceId'] ?? '').toString(),
      enterpriseId: (map['enterpriseId'] ?? '').toString(),
      terminalName: (map['terminalName'] ?? 'Biometric Terminal').toString(),
      type: TerminalAlarmType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TerminalAlarmType.unauthorizedFace,
      ),
      severity: TerminalAlarmSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => TerminalAlarmSeverity.high,
      ),
      timestamp: AppFormatUtils.parseTimestamp(map['timestamp']),
      details: (map['details'] ?? '').toString(),
      employeeId: map['employeeId'] as String?,
      employeeName: map['employeeName'] as String?,
      snapshotUrl: map['snapshotUrl'] as String?,
      isAcknowledged: map['isAcknowledged'] as bool? ?? false,
      acknowledgedBy: map['acknowledgedBy'] as String?,
      acknowledgedAt: AppFormatUtils.parseTimestamp(map['acknowledgedAt']),
    );
  }
}
