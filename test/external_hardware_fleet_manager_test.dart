import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/external_hardware_fleet_manager_service.dart';

void main() {
  group('ExternalHardwareFleetManagerService Suite', () {
    test('Calculates fleet availability percentage and protocol distribution', () {
      final summary = ExternalHardwareFleetManagerService.instance.aggregateFleetStatus(
        totalDevices: 20,
        onlineDevices: 19,
        hikvisionCount: 12,
        zktecoCount: 8,
        dailyPunches: 2450,
        blockedSpoofs: 3,
        avgLatencyMs: 38.0,
      );

      expect(summary.totalTerminals, equals(20));
      expect(summary.activeOnlineTerminals, equals(19));
      expect(summary.fleetAvailabilityPercent, equals(95.0));
      expect(summary.hikvisionMinMoeCount, equals(12));
      expect(summary.zktecoAdmsCount, equals(8));
      expect(summary.totalDailyHardwarePunches, equals(2450));
      expect(summary.antiSpoofAttacksBlocked, equals(3));
    });
  });
}
