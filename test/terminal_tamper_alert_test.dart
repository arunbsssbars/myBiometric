import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/terminal_tamper_alert_service.dart';
import 'package:mybiometric/views/terminal_tamper_alert_card.dart';

void main() {
  group('TerminalTamperAlertService Suite', () {
    late TerminalTamperAlertService service;

    setUp(() {
      service = TerminalTamperAlertService();
      service.clearForTesting();
    });

    test('Records chassis switch tampering and assigns critical severity', () {
      final event = service.recordIncident(
        deviceId: 'TERM_LOBBY_01',
        enterpriseId: 'ENT_ACME',
        sensorType: TamperSensorType.chassisSwitch,
        sensorValue: 1.0,
      );

      expect(event.severity, equals(TamperSeverity.critical));
      expect(event.deviceId, equals('TERM_LOBBY_01'));
      expect(service.isEnclosureCompromised('TERM_LOBBY_01'), isTrue);
      expect(service.calculateDeviceRiskScore('TERM_LOBBY_01'), greaterThanOrEqualTo(40.0));
    });

    test('Records accelerometer shock and calculates tiered severity', () {
      final lowShock = service.recordIncident(
        deviceId: 'TERM_GATE_02',
        enterpriseId: 'ENT_ACME',
        sensorType: TamperSensorType.accelerometerShock,
        sensorValue: 1.5,
      );
      expect(lowShock.severity, equals(TamperSeverity.low));

      final midShock = service.recordIncident(
        deviceId: 'TERM_GATE_02',
        enterpriseId: 'ENT_ACME',
        sensorType: TamperSensorType.accelerometerShock,
        sensorValue: 2.5,
      );
      expect(midShock.severity, equals(TamperSeverity.warning));

      final highShock = service.recordIncident(
        deviceId: 'TERM_GATE_02',
        enterpriseId: 'ENT_ACME',
        sensorType: TamperSensorType.accelerometerShock,
        sensorValue: 5.2,
      );
      expect(highShock.severity, equals(TamperSeverity.critical));
    });

    test('Allows admin to acknowledge tamper alert and updates risk score', () {
      final event = service.recordIncident(
        deviceId: 'TERM_01',
        enterpriseId: 'ENT_ACME',
        sensorType: TamperSensorType.cableDisconnect,
        sensorValue: 1.0,
      );

      expect(service.getUnacknowledgedAlerts(deviceId: 'TERM_01').length, equals(1));

      final success = service.acknowledgeAlert(event.id, 'admin_arun');
      expect(success, isTrue);
      expect(service.getUnacknowledgedAlerts(deviceId: 'TERM_01').length, equals(0));
      expect(service.isEnclosureCompromised('TERM_01'), isFalse);
    });

    test('Serializes and deserializes TerminalTamperEvent cleanly', () {
      final original = TerminalTamperEvent(
        id: 'evt_123',
        deviceId: 'DEV_99',
        enterpriseId: 'ENT_01',
        sensorType: TamperSensorType.opticalLightLeak,
        severity: TamperSeverity.warning,
        timestamp: DateTime(2026, 10, 8, 12, 0),
        sensorValue: 55.4,
        description: 'Lux spike detected inside chassis',
        acknowledged: false,
      );

      final json = original.toJson();
      final restored = TerminalTamperEvent.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.sensorType, equals(original.sensorType));
      expect(restored.sensorValue, closeTo(55.4, 0.01));
    });

    testWidgets('TerminalTamperAlertCard renders without overflow', (tester) async {
      final event = TerminalTamperEvent(
        id: 'evt_test',
        deviceId: 'TERM_ENTRANCE_ALPHA',
        enterpriseId: 'ENT_ALPHA',
        sensorType: TamperSensorType.chassisSwitch,
        severity: TamperSeverity.critical,
        timestamp: DateTime.now(),
        sensorValue: 1.0,
        description: 'Physical enclosure opened (Chassis microswitch triggered)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalTamperAlertCard(
              event: event,
              onAcknowledge: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('TERM_ENTRANCE_ALPHA'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('Acknowledge'), findsOneWidget);
    });
  });
}
