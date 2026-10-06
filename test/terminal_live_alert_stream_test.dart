import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/external_biometric_device.dart';
import 'package:mybiometric/domain/models/terminal_live_alert.dart';
import 'package:mybiometric/services/terminal_live_alert_stream_service.dart';

void main() {
  group('Terminal Live Alert Stream Suite', () {
    final testDevice = BiometricTerminalDevice(
      id: 'term_front_door',
      enterpriseId: 'ent_demo',
      name: 'North Turnstile MinMoe',
      modelName: 'DS-K1T343MWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.100',
      createdAt: DateTime(2026, 1, 1),
    );

    test('TerminalLiveAlert serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 3, 2, 0);
      final alert = TerminalLiveAlert(
        alertId: 'ALT-1001',
        deviceId: 'term_front_door',
        deviceName: 'North Turnstile MinMoe',
        alertType: TerminalAlertType.tamperAlarm,
        doorIndex: 1,
        isDoorUnlocked: false,
        description: 'Hardware tamper detected.',
        timestamp: now,
      );

      final json = alert.toJson();
      final reconstructed = TerminalLiveAlert.fromJson(json);

      expect(reconstructed.alertId, equals('ALT-1001'));
      expect(reconstructed.alertType, equals(TerminalAlertType.tamperAlarm));
      expect(reconstructed.isSecurityThreat, isTrue);
      expect(reconstructed.isDoorUnlocked, isFalse);
    });

    test('TerminalLiveAlertStreamService parses raw ISAPI alerts correctly', () {
      final service = TerminalLiveAlertStreamService();

      final tamperAlert = service.parseRawAlert(
        device: testDevice,
        rawContent: '<EventNotificationAlert><eventType>tamperAlarm</eventType></EventNotificationAlert>',
      );
      expect(tamperAlert.alertType, equals(TerminalAlertType.tamperAlarm));
      expect(tamperAlert.isSecurityThreat, isTrue);

      final faceAlert = service.parseRawAlert(
        device: testDevice,
        rawContent: '<EventNotificationAlert><eventType>AccessControllerEvent</eventType></EventNotificationAlert>',
      );
      expect(faceAlert.alertType, equals(TerminalAlertType.faceMatchSuccess));
      expect(faceAlert.isDoorUnlocked, isTrue);

      final spoofAlert = service.parseRawAlert(
        device: testDevice,
        rawContent: '<EventNotificationAlert><eventType>livenessFailed</eventType></EventNotificationAlert>',
      );
      expect(spoofAlert.alertType, equals(TerminalAlertType.spoofingAttemptDetected));
      expect(spoofAlert.isDoorUnlocked, isFalse);

      service.dispose();
    });
  });
}
