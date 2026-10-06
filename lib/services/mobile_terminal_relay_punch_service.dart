import 'dart:math' as math;
import '../domain/models/mobile_terminal_relay_punch.dart';

/// Service authorizing and triggering physical door/relay strikes via biometric machine API
class MobileTerminalRelayPunchService {
  /// Computes distance in meters using the Haversine formula
  double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);

  /// Validates security preconditions before issuing machine relay strike
  bool canTriggerRelay(MobileTerminalRelayPunch punch) {
    // 1. Employee must have verified local biometric on smartphone
    if (!punch.biometricVerifiedOnPhone) {
      return false;
    }

    // 2. Geofence distance to terminal check
    final distance = calculateDistanceMeters(
      punch.userLatitude,
      punch.userLongitude,
      punch.terminalLatitude,
      punch.terminalLongitude,
    );

    return distance <= punch.maxAllowedDistanceMeters;
  }

  /// Triggers hardware relay strike on physical terminal
  Future<bool> triggerTerminalDoorRelay(MobileTerminalRelayPunch punch) async {
    if (!canTriggerRelay(punch)) {
      return false;
    }

    // In enterprise deployment, dispatches ISAPI /ISAPI/AccessControl/RemoteControl/door/1 strike
    return true;
  }
}
