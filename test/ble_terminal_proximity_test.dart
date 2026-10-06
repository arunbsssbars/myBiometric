import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/ble_terminal_proximity_beacon.dart';
import 'package:mybiometric/services/ble_terminal_proximity_service.dart';

void main() {
  group('BleTerminalProximityService Tests', () {
    late BleTerminalProximityService service;

    setUp(() {
      service = BleTerminalProximityService();
    });

    test('generates valid beacon and verifies within acceptable proximity RSSI', () {
      final beacon = service.generateBeacon(
        employeeId: 'EMP-001',
        enterpriseId: 'ENT-ALPHA',
        rssiThresholdDbm: -70,
      );

      expect(beacon.employeeId, 'EMP-001');
      expect(beacon.enterpriseId, 'ENT-ALPHA');
      expect(beacon.encryptedPayload.isNotEmpty, true);

      // Within distance (-65 is stronger than -70 threshold)
      final isValidClose = service.verifyProximityPayload(
        beacon: beacon,
        measuredRssi: -65,
      );
      expect(isValidClose, true);

      // Too far away (-85 is weaker than -70 threshold)
      final isValidFar = service.verifyProximityPayload(
        beacon: beacon,
        measuredRssi: -85,
      );
      expect(isValidFar, false);
    });

    test('serialization roundtrip preserves beacon properties', () {
      final beacon = service.generateBeacon(
        employeeId: 'EMP-002',
        enterpriseId: 'ENT-BETA',
      );

      final map = beacon.toMap();
      final restored = BleTerminalProximityBeacon.fromMap(map);

      expect(restored.employeeId, beacon.employeeId);
      expect(restored.encryptedPayload, beacon.encryptedPayload);
      expect(restored.major, beacon.major);
    });
  });
}
