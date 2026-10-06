import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/external_biometric_device.dart';
import 'package:mybiometric/services/external_terminal_webhook_service.dart';

void main() {
  group('External Terminal Push SDK & Webhook Ingestion Suite', () {
    late ExternalTerminalWebhookService webhookService;

    setUp(() {
      webhookService = ExternalTerminalWebhookService();
    });

    test('ingestPushPayload processes Hikvision ISUP 5.0 Push JSON payload', () {
      final isupJson = jsonEncode({
        'events': [
          {
            'eventId': 'isup-evt-1',
            'employeeNoString': 'EMP-771',
            'name': 'Sarah Connor',
            'dateTime': '2026-10-01T09:15:00+05:30',
            'eventType': 'AccessControlCheckIn',
            'attendanceStatus': 0,
            'authMode': 'face',
            'similarity': 99.2,
          }
        ]
      });

      final events = webhookService.ingestPushPayload(
        protocol: TerminalProtocol.hikvisionIsupPush,
        rawBody: isupJson,
        deviceId: 'minmoe-gate-1',
      );

      expect(events.length, 1);
      final e = events.first;
      expect(e.employeeId, 'EMP-771');
      expect(e.employeeName, 'Sarah Connor');
      expect(e.punchType, 'PUNCH_IN');
      expect(e.authMode, DeviceAuthMode.face);
      expect(e.similarityScore, 99.2);
    });

    test('ingestPushPayload processes ZKTeco ADMS raw tab-separated stream', () {
      const zkTecoPayload = 'EMP-882\t2026-10-01 18:30:00\tO\t1\nEMP-883\t2026-10-01 18:31:00\tI\t15';

      final events = webhookService.ingestPushPayload(
        protocol: TerminalProtocol.zkTecoAdms,
        rawBody: zkTecoPayload,
        deviceId: 'zk-device-2',
      );

      expect(events.length, 2);
      expect(events[0].employeeId, 'EMP-882');
      expect(events[0].punchType, 'PUNCH_OUT');
      expect(events[0].authMode, DeviceAuthMode.fingerprint);

      expect(events[1].employeeId, 'EMP-883');
      expect(events[1].punchType, 'PUNCH_IN');
      expect(events[1].authMode, DeviceAuthMode.face);
    });

    test('ingestPushPayload returns empty list on blank or corrupted payload', () {
      final empty = webhookService.ingestPushPayload(
        protocol: TerminalProtocol.genericWebhook,
        rawBody: '',
        deviceId: 'dev-1',
      );
      expect(empty, isEmpty);
    });
  });
}
