import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/nearby_terminal_discovery_service.dart';

void main() {
  group('NearbyTerminalDiscoveryService Tests', () {
    late NearbyTerminalDiscoveryService service;

    setUp(() {
      service = NearbyTerminalDiscoveryService();
    });

    test('scans and locates nearby biometric terminals on subnet', () async {
      final terminals = await service.scanNearbyTerminals(subnetPrefix: '192.168.1');
      expect(terminals.length, 2);
      expect(terminals.first.deviceName.contains('MinMoe'), true);
      expect(terminals.first.estimatedDistanceMeters > 0, true);
    });

    test('accurately calculates path loss distance from RSSI', () {
      final dist1m = service.estimateDistanceMeters(-59);
      expect(dist1m, 1.0);

      final distFar = service.estimateDistanceMeters(-79);
      expect(distFar > 5.0, true);
    });
  });
}
