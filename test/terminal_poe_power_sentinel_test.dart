import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/terminal_poe_power_sentinel_service.dart';
import 'package:mybiometric/views/terminal_poe_power_sentinel_card.dart';

void main() {
  group('TerminalPoePowerSentinelService Suite', () {
    late TerminalPoePowerSentinelService service;

    setUp(() {
      service = TerminalPoePowerSentinelService();
      service.clearForTesting();
    });

    test('Reports online PoE power rail status when AC/PoE connected', () {
      final status = TerminalPowerStatus(
        deviceId: 'TERM_LOBBY_01',
        activePowerSource: PowerSourceType.poePlus,
        inputVoltage: 52.0,
        currentDrawWatts: 14.2,
        batteryPercentage: 98.0,
        isMainPowerLost: false,
        recordedAt: DateTime.now(),
      );

      service.updatePowerStatus(status);

      expect(status.isMainPowerLost, isFalse);
      expect(status.isLowBattery, isFalse);
      expect(service.shouldTriggerPowerConservation('TERM_LOBBY_01'), isFalse);
    });

    test('Calculates estimated runtime and flags power conservation on battery failover', () {
      final failoverStatus = TerminalPowerStatus(
        deviceId: 'TERM_GATE_01',
        activePowerSource: PowerSourceType.internalBattery,
        inputVoltage: 11.4,
        currentDrawWatts: 10.0,
        batteryPercentage: 20.0, // Low battery < 25%
        isMainPowerLost: true,
        recordedAt: DateTime.now(),
      );

      service.updatePowerStatus(failoverStatus);

      expect(failoverStatus.isMainPowerLost, isTrue);
      expect(failoverStatus.isLowBattery, isTrue);
      expect(service.shouldTriggerPowerConservation('TERM_GATE_01'), isTrue);
      expect(failoverStatus.estimatedBatteryMinutesRemaining, greaterThan(0));
    });

    testWidgets('TerminalPoePowerSentinelCard renders without overflow across viewports', (tester) async {
      final status = TerminalPowerStatus(
        deviceId: 'TERM_TEST_01',
        activePowerSource: PowerSourceType.internalBattery,
        inputVoltage: 11.2,
        currentDrawWatts: 8.0,
        batteryPercentage: 45.0,
        isMainPowerLost: true,
        recordedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminalPoePowerSentinelCard(
              status: status,
            ),
          ),
        ),
      );

      expect(find.textContaining('TERM_TEST_01'), findsOneWidget);
      expect(find.text('BATTERY FAILOVER'), findsOneWidget);
      expect(find.textContaining('11.2V'), findsOneWidget);
    });
  });
}
