import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/terminal_alarm_event.dart';

/// Monitor service for external terminal security alarms, tamper events, and access anomalies.
class TerminalAlarmEventMonitor {
  final FirebaseFirestore _firestore;

  TerminalAlarmEventMonitor({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Ingests and classifies a raw alarm notification from a biometric terminal.
  Future<TerminalAlarmEvent> ingestAlarm({
    required String enterpriseId,
    required String deviceId,
    required String terminalName,
    required TerminalAlarmType type,
    TerminalAlarmSeverity severity = TerminalAlarmSeverity.high,
    required String details,
    String? employeeId,
    String? employeeName,
    String? snapshotUrl,
    DateTime? timestamp,
  }) async {
    final eventDoc = _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminal_alarms')
        .doc();

    final alarm = TerminalAlarmEvent(
      id: eventDoc.id,
      deviceId: deviceId,
      enterpriseId: enterpriseId,
      terminalName: terminalName,
      type: type,
      severity: severity,
      timestamp: timestamp ?? DateTime.now(),
      details: details,
      employeeId: employeeId,
      employeeName: employeeName,
      snapshotUrl: snapshotUrl,
      isAcknowledged: false,
    );

    await eventDoc.set(alarm.toMap());

    // Also post high-priority alert to enterprise notifications
    final notifDoc = _firestore.collection('notifications').doc();
    await notifDoc.set({
      'target': 'ENTERPRISE_ADMIN',
      'enterpriseId': enterpriseId,
      'type': 'GEOFENCE_BREACH', // Mapped to existing high-priority notification channel
      'title': '🚨 Terminal Alert: ${alarm.typeDisplayName}',
      'body': '[$terminalName] $details',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return alarm;
  }

  /// Maps Hikvision ISAPI AcsEvent alarm codes to domain alarm types.
  static TerminalAlarmType? mapHikvisionAlarmCode(int major, int minor) {
    if (major == 5) {
      switch (minor) {
        case 2:
          return TerminalAlarmType.doorForcedOpen;
        case 27:
          return TerminalAlarmType.deviceTamper;
        case 75:
          return TerminalAlarmType.antiPassbackBreach;
        case 34:
          return TerminalAlarmType.duressPinTriggered;
        case 32:
          return TerminalAlarmType.multipleAuthFailures;
        case 40:
          return TerminalAlarmType.faceMaskMissing;
        case 37:
          return TerminalAlarmType.blacklistDetected;
      }
    }
    return null;
  }

  /// Streams active (unacknowledged) alarms for an enterprise.
  Stream<List<TerminalAlarmEvent>> streamActiveAlarms(String enterpriseId) {
    return _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminal_alarms')
        .where('isAcknowledged', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TerminalAlarmEvent.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Acknowledges an active alarm event.
  Future<void> acknowledgeAlarm({
    required String enterpriseId,
    required String alarmId,
    required String adminName,
  }) async {
    await _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminal_alarms')
        .doc(alarmId)
        .update({
      'isAcknowledged': true,
      'acknowledgedBy': adminName,
      'acknowledgedAt': FieldValue.serverTimestamp(),
    });
  }
}
