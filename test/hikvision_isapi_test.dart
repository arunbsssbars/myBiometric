import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_biometric_device.dart';
import 'package:mybiometric_app/services/hikvision_isapi_service.dart';

void main() {
  group('Hikvision ISAPI Protocol & AcsEvents Parser Suite', () {
    late HikvisionIsapiService isapiService;

    setUp(() {
      isapiService = HikvisionIsapiService();
    });

    test('parseAcsEventsResponse parses standard Hikvision MinMoe Face authentication events', () {
      final sampleHikvisionJson = jsonEncode({
        'AcsEvent': {
          'searchID': '170000000',
          'totalMatches': 2,
          'responseStatusStrg': 'OK',
          'numOfMatches': 2,
          'InfoList': [
            {
              'major': 5,
              'minor': 75,
              'time': '2026-10-01T09:32:00+05:30',
              'cardNo': '1001',
              'cardType': 1,
              'name': 'Arun Sharma',
              'employeeNoString': 'EMP-001',
              'authMode': 15,
              'serialNo': 1024,
              'userType': 'normal',
              'currentVerifyMode': 'face',
              'attendanceStatus': 0, // Check-in
              'similarity': 98.6,
            },
            {
              'major': 5,
              'minor': 76,
              'time': '2026-10-01T18:05:00+05:30',
              'cardNo': '1002',
              'cardType': 1,
              'name': 'Rajesh Kumar',
              'employeeNoString': 'EMP-002',
              'authMode': 17,
              'serialNo': 1025,
              'userType': 'normal',
              'currentVerifyMode': 'fingerprint',
              'attendanceStatus': 1, // Check-out
              'similarity': 95.0,
            }
          ]
        }
      });

      final parsedEvents = isapiService.parseAcsEventsResponse(sampleHikvisionJson, 'device-lobby-1');

      expect(parsedEvents.length, 2);

      // Verify Event 1 (Face Check-In)
      final event1 = parsedEvents[0];
      expect(event1.employeeId, 'EMP-001');
      expect(event1.employeeName, 'Arun Sharma');
      expect(event1.punchType, 'PUNCH_IN');
      expect(event1.authMode, DeviceAuthMode.face);
      expect(event1.similarityScore, 98.6);
      expect(event1.deviceId, 'device-lobby-1');

      // Verify Event 2 (Fingerprint Check-Out)
      final event2 = parsedEvents[1];
      expect(event2.employeeId, 'EMP-002');
      expect(event2.employeeName, 'Rajesh Kumar');
      expect(event2.punchType, 'PUNCH_OUT');
      expect(event2.authMode, DeviceAuthMode.fingerprint);
      expect(event2.similarityScore, 95.0);
    });

    test('parseAcsEventsResponse handles empty or malformed JSON defensively', () {
      final emptyEvents = isapiService.parseAcsEventsResponse('{}', 'dev-1');
      expect(emptyEvents, isEmpty);

      final malformedEvents = isapiService.parseAcsEventsResponse('not-json-content', 'dev-1');
      expect(malformedEvents, isEmpty);
    });
  });
}
