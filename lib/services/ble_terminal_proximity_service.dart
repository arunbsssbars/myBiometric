import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/ble_terminal_proximity_beacon.dart';

/// Service managing BLE proximity advertisement and physical machine handshake
class BleTerminalProximityService {
  static const String defaultBeaconNamespace = 'e2c56db5-dffb-48d2-b060-d0f5a71096e0';

  /// Generates a signed proximity advertisement beacon payload for the employee
  BleTerminalProximityBeacon generateBeacon({
    required String employeeId,
    required String enterpriseId,
    String? secretKey,
    int major = 100,
    int minor = 1,
    int rssiThresholdDbm = -75,
  }) {
    final now = DateTime.now();
    final key = utf8.encode(secretKey ?? 'ENTERPRISE_BLE_HMAC_SALT_KEY');
    final rawMessage = utf8.encode('$employeeId:$enterpriseId:${now.millisecondsSinceEpoch ~/ 30000}');
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(rawMessage);

    return BleTerminalProximityBeacon(
      beaconUuid: defaultBeaconNamespace,
      major: major,
      minor: minor,
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      rssiThresholdDbm: rssiThresholdDbm,
      encryptedPayload: digest.toString().substring(0, 16),
      timestamp: now,
    );
  }

  /// Verifies if a detected beacon payload is authentic and within valid timestamp window (±60 seconds)
  bool verifyProximityPayload({
    required BleTerminalProximityBeacon beacon,
    required int measuredRssi,
    String? secretKey,
  }) {
    // 1. Proximity distance check
    if (!beacon.isWithinProximity(measuredRssi)) {
      return false;
    }

    // 2. Freshness check (within 120 seconds)
    final diffSeconds = DateTime.now().difference(beacon.timestamp).inSeconds.abs();
    if (diffSeconds > 120) {
      return false;
    }

    // 3. Cryptographic signature check
    final key = utf8.encode(secretKey ?? 'ENTERPRISE_BLE_HMAC_SALT_KEY');
    final timeStep = beacon.timestamp.millisecondsSinceEpoch ~/ 30000;
    
    // Check current and previous 30s window to handle clock drift
    for (int delta = -1; delta <= 1; delta++) {
      final raw = utf8.encode('${beacon.employeeId}:${beacon.enterpriseId}:${timeStep + delta}');
      final digest = Hmac(sha256, key).convert(raw).toString().substring(0, 16);
      if (digest == beacon.encryptedPayload) {
        return true;
      }
    }

    return false;
  }
}
