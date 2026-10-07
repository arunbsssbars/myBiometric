import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/terminal_environment_sensor_service.dart';
import 'package:mybiometric/views/terminal_environment_sensor_card.dart';

void main() {
  group('TerminalEnvironmentSensorService Suite', () {
    late TerminalEnvironmentSensorService service;

    setUp(() {
      service = TerminalEnvironmentSensorService();
      service.clearForTesting();
    });

    test('Classifies optimal indoor environment accurately', () {
      final telemetry = TerminalEnvironmentTelemetry(
        deviceId: 'TERM_LOBBY',
        temperatureCelsius: 22.5,
        relativeHumidityPercent: 45.0,
        ambientLightLux: 450.0,
        recordedAt: DateTime.now(),
      );

      service.recordTelemetry(telemetry);

      expect(telemetry.operatingState, equals(SensorOperatingState.optimal));
      expect(telemetry.isLowLight, isFalse);
      expect(telemetry.isOverheating, isFalse);
      expect(service.shouldTriggerAuxiliaryIllumination('TERM_LOBBY'), isFalse);
    });

    test('Flags low-light environment and triggers auxiliary illumination requirement', () {
      final lowLight = TerminalEnvironmentTelemetry(
        deviceId: 'TERM_BASEMENT',
        temperatureCelsius: 18.0,
        relativeHumidityPercent: 55.0,
        ambientLightLux: 25.0, // Low light (<40 lux)
        recordedAt: DateTime.now(),
      );

      service.recordTelemetry(lowLight);

      expect(lowLight.operatingState, equals(SensorOperatingState.warning));
      expect(lowLight.isLowLight, isTrue);
      expect(service.shouldTriggerAuxiliaryIllumination('TERM_BASEMENT'), isTrue);
      expect(lowLight.environmentStatusSummary, contains('Sub-optimal Lighting'));
    });

    test('Classifies severe overheating as critical operating state', () {
      final overheating = TerminalEnvironmentTelemetry(
        deviceId: 'TERM_ROOF',
        temperatureCelsius: 68.0,
        relativeHumidityPercent: 30.0,
        ambientLightLux: 1500.0,
        recordedAt: DateTime.now(),
      );

      expect(overheating.operatingState, equals(SensorOperatingState.critical));
      expect(overheating.isOverheating, isTrue);
    });

    testWidgets('TerminalEnvironmentSensorCard renders without overflow across viewports', (tester) async {
      final telemetry = TerminalEnvironmentTelemetry(
        deviceId: 'TERM_EXTERIOR_01',
        temperatureCelsius: 32.0,
        relativeHumidityPercent: 60.0,
        ambientLightLux: 800.0,
        recordedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalEnvironmentSensorCard(
              telemetry: telemetry,
            ),
          ),
        ),
      );

      expect(find.textContaining('TERM_EXTERIOR_01'), findsOneWidget);
      expect(find.text('OPTIMAL'), findsOneWidget);
      expect(find.textContaining('32.0°C'), findsOneWidget);
    });
  });
}
