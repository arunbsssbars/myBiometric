import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/ble_beacon_profile.dart';
import 'package:mybiometric_app/services/ble_beacon_verification_service.dart';

void main() {
  group('BleBeaconVerificationService Tests', () {
    const beacon = BleBeaconProfile(
      beaconId: 'b-01',
      enterpriseId: 'ent-1',
      branchId: 'branch-blr',
      name: 'Turnstile A Beacon',
      uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
      major: 10,
      minor: 1,
      txPower: -59,
      minAcceptableRssi: -75,
    );

    test('Estimates distance using path-loss formula', () {
      // At -59 dBm (measured power), distance is 1.0m
      final dist1m = BleBeaconVerificationService.estimateDistanceMeters(
        rssi: -59,
        txPower: -59,
      );
      expect(dist1m, closeTo(1.0, 0.05));

      // At lower RSSI (e.g. -75 dBm), distance is greater
      final distFar = BleBeaconVerificationService.estimateDistanceMeters(
        rssi: -75,
        txPower: -59,
      );
      expect(distFar, greaterThan(3.0));
    });

    test('Verifies presence when matching beacon signal is above threshold', () {
      final reading = BeaconSignalReading(
        uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        major: 10,
        minor: 1,
        rssi: -65, // Stronger than -75 dBm threshold
        scannedAt: DateTime.now(),
      );

      final res = BleBeaconVerificationService.verifyProximity(
        registeredBeacons: [beacon],
        scannedReadings: [reading],
      );

      expect(res.isVerified, isTrue);
      expect(res.matchedBeacon?.beaconId, equals('b-01'));
      expect(res.measuredRssi, equals(-65));
      expect(res.statusDescription, contains('Verified at Turnstile A Beacon'));
    });

    test('Rejects verification when signal is too weak (parking lot spoofing defense)', () {
      final weakReading = BeaconSignalReading(
        uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        major: 10,
        minor: 1,
        rssi: -88, // Weaker than -75 dBm threshold
        scannedAt: DateTime.now(),
      );

      final res = BleBeaconVerificationService.verifyProximity(
        registeredBeacons: [beacon],
        scannedReadings: [weakReading],
      );

      expect(res.isVerified, isFalse);
      expect(res.matchedBeacon?.beaconId, equals('b-01'));
      expect(res.statusDescription, contains('Signal too weak'));
    });

    test('Serializes and deserializes BleBeaconProfile cleanly', () {
      final map = beacon.toMap();
      final revived = BleBeaconProfile.fromMap(map);

      expect(revived.beaconId, equals(beacon.beaconId));
      expect(revived.uuid, equals(beacon.uuid));
      expect(revived.txPower, equals(-59));
      expect(revived.minAcceptableRssi, equals(-75));
    });
  });
}
