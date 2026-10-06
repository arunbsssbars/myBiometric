import 'package:flutter/foundation.dart';

enum MinMoeAlarmSeverity {
  info,
  warning,
  critical,
}

/// Real-time security event emitted by Hikvision MinMoe via HTTP multipart listen or alert stream
@immutable
class MinMoeAlertEvent {
  final String eventId;
  final String terminalId;
  final String majorEventType; // e.g. 'EVENT_DOOR_TAMPER', 'EVENT_FAKE_FACE_REJECT', 'EVENT_DURESS'
  final String subEventType;
  final MinMoeAlarmSeverity severity;
  final String? cardNo;
  final String? employeeNo;
  final double? faceMatchSimilarity;
  final String? snapshotJpegBase64;
  final DateTime eventTimestamp;

  const MinMoeAlertEvent({
    required this.eventId,
    required this.terminalId,
    required this.majorEventType,
    required this.subEventType,
    this.severity = MinMoeAlarmSeverity.warning,
    this.cardNo,
    this.employeeNo,
    this.faceMatchSimilarity,
    this.snapshotJpegBase64,
    required this.eventTimestamp,
  });

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'terminalId': terminalId,
        'majorEventType': majorEventType,
        'subEventType': subEventType,
        'severity': severity.name,
        'cardNo': cardNo,
        'employeeNo': employeeNo,
        'faceMatchSimilarity': faceMatchSimilarity,
        'snapshotJpegBase64': snapshotJpegBase64,
        'eventTimestamp': eventTimestamp.toIso8601String(),
      };

  factory MinMoeAlertEvent.fromMap(Map<String, dynamic> map) =>
      MinMoeAlertEvent(
        eventId: map['eventId'] as String? ?? '',
        terminalId: map['terminalId'] as String? ?? '',
        majorEventType: map['majorEventType'] as String? ?? 'GENERAL_ALERT',
        subEventType: map['subEventType'] as String? ?? 'UNKNOWN',
        severity: MinMoeAlarmSeverity.values.firstWhere(
          (e) => e.name == map['severity'],
          orElse: () => MinMoeAlarmSeverity.warning,
        ),
        cardNo: map['cardNo'] as String?,
        employeeNo: map['employeeNo'] as String?,
        faceMatchSimilarity: (map['faceMatchSimilarity'] as num?)?.toDouble(),
        snapshotJpegBase64: map['snapshotJpegBase64'] as String?,
        eventTimestamp: map['eventTimestamp'] != null
            ? DateTime.tryParse(map['eventTimestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
