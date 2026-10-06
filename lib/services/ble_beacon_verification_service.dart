import 'dart:math' as math;
import '../domain/models/ble_beacon_profile.dart';

/// Service managing BLE Beacon discovery, distance estimation, and attendance verification
class BleBeaconVerificationService {
  /// Estimates distance in meters from RSSI and TxPower using log-distance path loss model
  static double estimateDistanceMeters({
    required int rssi,
    required int txPower,
    double pathLossExponent = 2.2, // Typical indoor office environment
  }) {
    if (rssi == 0) return double.infinity;
    final ratio = (txPower - rssi) / (10.0 * pathLossExponent);
    return math.pow(10.0, ratio).toDouble();
  }

  /// Evaluates scanned readings against enterprise beacon profiles
  static BeaconVerificationResult verifyProximity({
    required List<BleBeaconProfile> registeredBeacons,
    required List<BeaconSignalReading> scannedReadings,
    String? requiredBranchId,
  }) {
    final activeBeacons = registeredBeacons
        .where((b) => b.isActive)
        .where((b) => requiredBranchId == null || b.branchId == requiredBranchId)
        .toList();

    if (activeBeacons.isEmpty) {
      return const BeaconVerificationResult(
        isVerified: false,
        statusDescription: 'No active beacons registered for this facility',
      );
    }

    if (scannedReadings.isEmpty) {
      return const BeaconVerificationResult(
        isVerified: false,
        statusDescription: 'No Bluetooth beacon signals detected nearby',
      );
    }

    BleBeaconProfile? bestBeacon;
    int bestRssi = -999;
    double bestDistance = double.infinity;

    for (final reading in scannedReadings) {
      for (final beacon in activeBeacons) {
        if (_matchesBeacon(reading, beacon)) {
          if (reading.rssi > bestRssi) {
            bestRssi = reading.rssi;
            bestBeacon = beacon;
            bestDistance = estimateDistanceMeters(
              rssi: reading.rssi,
              txPower: beacon.txPower,
            );
          }
        }
      }
    }

    if (bestBeacon == null) {
      return const BeaconVerificationResult(
        isVerified: false,
        statusDescription: 'Detected beacons do not belong to this enterprise',
      );
    }

    final isWithinThreshold = bestRssi >= bestBeacon.minAcceptableRssi;

    if (!isWithinThreshold) {
      return BeaconVerificationResult(
        isVerified: false,
        matchedBeacon: bestBeacon,
        measuredRssi: bestRssi,
        estimatedDistanceMeters: bestDistance,
        statusDescription:
            'Signal too weak (${bestRssi} dBm < ${bestBeacon.minAcceptableRssi} dBm threshold, approx ${bestDistance.toStringAsFixed(1)}m away)',
      );
    }

    return BeaconVerificationResult(
      isVerified: true,
      matchedBeacon: bestBeacon,
      measuredRssi: bestRssi,
      estimatedDistanceMeters: bestDistance,
      statusDescription:
          'Verified at ${bestBeacon.name} (${bestRssi} dBm, ~${bestDistance.toStringAsFixed(1)}m)',
    );
  }

  static bool _matchesBeacon(BeaconSignalReading reading, BleBeaconProfile beacon) {
    return reading.uuid.trim().toLowerCase() == beacon.uuid.trim().toLowerCase() &&
        reading.major == beacon.major &&
        reading.minor == beacon.minor;
  }
}
