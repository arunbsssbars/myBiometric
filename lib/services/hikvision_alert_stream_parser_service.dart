import '../domain/models/minmoe_alert_event.dart';

/// Service parsing Hikvision ISAPI multipart/mixed continuous event streams
class HikvisionAlertStreamParserService {
  HikvisionAlertStreamParserService._internal();
  static final HikvisionAlertStreamParserService instance = HikvisionAlertStreamParserService._internal();

  /// Parses incoming JSON chunk from Hikvision /ISAPI/Event/notification/alertStream
  MinMoeAlertEvent? parseAlertJson({
    required String terminalId,
    required Map<String, dynamic> json,
  }) {
    final accessEvent = json['AccessControllerEvent'] as Map<String, dynamic>?;
    if (accessEvent == null) return null;

    final sub = accessEvent['subEventType']?.toString() ?? '75';
    final card = accessEvent['cardNo'] as String?;
    final employee = accessEvent['employeeNoString'] as String?;

    MinMoeAlarmSeverity severity = MinMoeAlarmSeverity.info;
    String majorDesc = 'ACCESS_EVENT';

    // MinMoe sub event mapping: 75 = Face verified, 76 = Face mismatch, 80 = Fake face, 81 = Tamper
    if (sub == '80' || sub == 'FAKE_FACE') {
      severity = MinMoeAlarmSeverity.critical;
      majorDesc = 'ANTI_SPOOF_REJECT';
    } else if (sub == '81' || sub == 'TAMPER') {
      severity = MinMoeAlarmSeverity.critical;
      majorDesc = 'HARDWARE_TAMPER_ALARM';
    } else if (sub == '75') {
      severity = MinMoeAlarmSeverity.info;
      majorDesc = 'FACE_VERIFIED_AUTHENTIC';
    }

    return MinMoeAlertEvent(
      eventId: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      terminalId: terminalId,
      majorEventType: majorDesc,
      subEventType: sub,
      severity: severity,
      cardNo: card,
      employeeNo: employee,
      faceMatchSimilarity: (accessEvent['similarity'] as num?)?.toDouble() ?? 0.0,
      eventTimestamp: DateTime.now(),
    );
  }
}
