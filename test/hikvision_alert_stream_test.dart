import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/minmoe_alert_event.dart';
import 'package:mybiometric/services/hikvision_alert_stream_parser_service.dart';

void main() {
  group('HikvisionAlertStreamParserService Suite', () {
    test('Parses genuine face verified access event', () {
      final json = {
        'eventType': 'AccessControllerEvent',
        'eventState': 'active',
        'AccessControllerEvent': {
          'majorEventType': 5,
          'subEventType': 75,
          'cardNo': 'CRD123',
          'employeeNoString': 'EMP99',
          'similarity': 0.94,
        }
      };

      final alert = HikvisionAlertStreamParserService.instance.parseAlertJson(
        terminalId: 'term_front_01',
        json: json,
      );

      expect(alert, isNotNull);
      expect(alert!.severity, equals(MinMoeAlarmSeverity.info));
      expect(alert.majorEventType, equals('FACE_VERIFIED_AUTHENTIC'));
      expect(alert.employeeNo, equals('EMP99'));
      expect(alert.faceMatchSimilarity, equals(0.94));
    });

    test('Parses anti-spoof attack rejection with critical severity', () {
      final json = {
        'eventType': 'AccessControllerEvent',
        'eventState': 'active',
        'AccessControllerEvent': {
          'majorEventType': 5,
          'subEventType': '80', // Fake face
          'cardNo': 'CRD_UNKNOWN',
          'similarity': 0.12,
        }
      };

      final alert = HikvisionAlertStreamParserService.instance.parseAlertJson(
        terminalId: 'term_front_01',
        json: json,
      );

      expect(alert, isNotNull);
      expect(alert!.severity, equals(MinMoeAlarmSeverity.critical));
      expect(alert.majorEventType, equals('ANTI_SPOOF_REJECT'));
    });
  });
}
