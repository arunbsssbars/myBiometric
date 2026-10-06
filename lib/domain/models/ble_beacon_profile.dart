/// Configured office BLE Beacon installed at turnstile or floor entrance
class BleBeaconProfile {
  final String beaconId;
  final String enterpriseId;
  final String branchId;
  final String name;
  final String uuid;
  final int major;
  final int minor;
  final int txPower; // Measured power at 1m (e.g. -59 dBm)
  final int minAcceptableRssi; // Threshold to prevent spoofing from parking lot (e.g. -78 dBm)
  final bool isActive;

  const BleBeaconProfile({
    required this.beaconId,
    required this.enterpriseId,
    required this.branchId,
    required this.name,
    required this.uuid,
    required this.major,
    required this.minor,
    this.txPower = -59,
    this.minAcceptableRssi = -78,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'beaconId': beaconId,
    'enterpriseId': enterpriseId,
    'branchId': branchId,
    'name': name,
    'uuid': uuid,
    'major': major,
    'minor': minor,
    'txPower': txPower,
    'minAcceptableRssi': minAcceptableRssi,
    'isActive': isActive,
  };

  factory BleBeaconProfile.fromMap(Map<String, dynamic> map) {
    return BleBeaconProfile(
      beaconId: map['beaconId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      name: map['name'] as String? ?? 'Turnstile Beacon',
      uuid: map['uuid'] as String? ?? '',
      major: (map['major'] as num?)?.toInt() ?? 0,
      minor: (map['minor'] as num?)?.toInt() ?? 0,
      txPower: (map['txPower'] as num?)?.toInt() ?? -59,
      minAcceptableRssi: (map['minAcceptableRssi'] as num?)?.toInt() ?? -78,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

/// A scanned raw BLE packet detected by mobile receiver
class BeaconSignalReading {
  final String uuid;
  final int major;
  final int minor;
  final int rssi; // Current received signal strength
  final DateTime scannedAt;

  const BeaconSignalReading({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.rssi,
    required this.scannedAt,
  });
}

/// Result of evaluating scanned signals against registered enterprise beacons
class BeaconVerificationResult {
  final bool isVerified;
  final BleBeaconProfile? matchedBeacon;
  final int measuredRssi;
  final double estimatedDistanceMeters;
  final String statusDescription;

  const BeaconVerificationResult({
    required this.isVerified,
    this.matchedBeacon,
    this.measuredRssi = -100,
    this.estimatedDistanceMeters = double.infinity,
    required this.statusDescription,
  });
}
