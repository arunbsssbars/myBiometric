import '../domain/models/network_geofence_policy.dart';

/// Result of multi-factor office location and network presence evaluation
class MultiFactorPresenceResult {
  final bool isValid;
  final String primaryChannel; // 'MOBILE_GPS', 'OFFICE_WIFI', 'DUAL_VERIFIED', 'UNKNOWN'
  final bool gpsMatched;
  final bool wifiMatched;
  final bool ipMatched;
  final String? failureReason;
  final Map<String, dynamic> auditMetadata;

  const MultiFactorPresenceResult({
    required this.isValid,
    required this.primaryChannel,
    this.gpsMatched = false,
    this.wifiMatched = false,
    this.ipMatched = false,
    this.failureReason,
    this.auditMetadata = const {},
  });

  /// Factory for successful GPS presence
  factory MultiFactorPresenceResult.gpsSuccess({
    required double distanceMeters,
    required double allowedRadiusMeters,
  }) =>
      MultiFactorPresenceResult(
        isValid: true,
        primaryChannel: 'MOBILE_GPS',
        gpsMatched: true,
        auditMetadata: {
          'distanceMeters': distanceMeters,
          'allowedRadiusMeters': allowedRadiusMeters,
        },
      );

  /// Factory for successful Wi-Fi office presence
  factory MultiFactorPresenceResult.wifiSuccess({
    required String ssid,
    String? bssid,
  }) =>
      MultiFactorPresenceResult(
        isValid: true,
        primaryChannel: 'OFFICE_WIFI',
        wifiMatched: true,
        auditMetadata: {
          'matchedSsid': ssid,
          if (bssid != null) 'matchedBssid': bssid,
        },
      );

  /// Factory for successful dual GPS and Wi-Fi presence
  factory MultiFactorPresenceResult.dualSuccess({
    required double distanceMeters,
    required String ssid,
  }) =>
      MultiFactorPresenceResult(
        isValid: true,
        primaryChannel: 'DUAL_VERIFIED',
        gpsMatched: true,
        wifiMatched: true,
        auditMetadata: {
          'distanceMeters': distanceMeters,
          'matchedSsid': ssid,
        },
      );

  /// Factory for failure
  factory MultiFactorPresenceResult.failure(String reason, {Map<String, dynamic>? metadata}) =>
      MultiFactorPresenceResult(
        isValid: false,
        primaryChannel: 'UNKNOWN',
        failureReason: reason,
        auditMetadata: metadata ?? const {},
      );
}

/// Service providing multi-factor enterprise office verification (GPS + Wi-Fi SSID/BSSID + IP)
class OfficeNetworkVerificationService {
  /// Evaluates multi-factor presence given current network and GPS metrics against policy
  static MultiFactorPresenceResult evaluatePresence({
    required NetworkGeofencePolicy policy,
    bool isGpsWithinGeofence = false,
    double distanceMeters = 0.0,
    double allowedRadiusMeters = 100.0,
    String? connectedSsid,
    String? connectedBssid,
    String? currentIp,
  }) {
    // 1. Evaluate Wi-Fi match
    bool wifiMatched = false;
    if (policy.isWifiGeofenceEnabled && connectedSsid != null) {
      final cleanSsid = connectedSsid.replaceAll('"', '').trim().toLowerCase();
      final ssidMatch = policy.allowedSsids
          .map((s) => s.toLowerCase().trim())
          .contains(cleanSsid);

      bool bssidMatch = true;
      if (policy.allowedBssids.isNotEmpty) {
        final cleanBssid = (connectedBssid ?? '').toLowerCase().trim();
        bssidMatch = policy.allowedBssids.contains(cleanBssid);
      }

      wifiMatched = ssidMatch && bssidMatch;
    }

    // 2. Evaluate IP match
    bool ipMatched = false;
    if (policy.isIpWhitelistEnabled && currentIp != null) {
      ipMatched = policy.allowedIpSubnets.any((subnet) => currentIp.startsWith(subnet));
      if (!ipMatched) {
        return MultiFactorPresenceResult.failure(
          'Connected device IP is not within enterprise allowed IP subnets',
          metadata: {'currentIp': currentIp},
        );
      }
    }

    // 3. Apply Policy Verification Mode
    switch (policy.mode) {
      case GeofenceVerificationMode.gpsOnly:
        if (isGpsWithinGeofence) {
          return MultiFactorPresenceResult.gpsSuccess(
            distanceMeters: distanceMeters,
            allowedRadiusMeters: allowedRadiusMeters,
          );
        }
        return MultiFactorPresenceResult.failure(
          'Outside office GPS boundary (${distanceMeters.toStringAsFixed(0)}m away, limit ${allowedRadiusMeters.toStringAsFixed(0)}m)',
          metadata: {'distanceMeters': distanceMeters},
        );

      case GeofenceVerificationMode.wifiOnly:
        if (wifiMatched) {
          return MultiFactorPresenceResult.wifiSuccess(
            ssid: connectedSsid ?? 'Office Wi-Fi',
            bssid: connectedBssid,
          );
        }
        return MultiFactorPresenceResult.failure(
          'Not connected to an authorized office Wi-Fi network',
          metadata: {'connectedSsid': connectedSsid, 'connectedBssid': connectedBssid},
        );

      case GeofenceVerificationMode.gpsOrWifi:
        if (isGpsWithinGeofence && wifiMatched) {
          return MultiFactorPresenceResult.dualSuccess(
            distanceMeters: distanceMeters,
            ssid: connectedSsid ?? 'Office Wi-Fi',
          );
        } else if (wifiMatched) {
          return MultiFactorPresenceResult.wifiSuccess(
            ssid: connectedSsid ?? 'Office Wi-Fi',
            bssid: connectedBssid,
          );
        } else if (isGpsWithinGeofence) {
          return MultiFactorPresenceResult.gpsSuccess(
            distanceMeters: distanceMeters,
            allowedRadiusMeters: allowedRadiusMeters,
          );
        }
        return MultiFactorPresenceResult.failure(
          'Neither office GPS perimeter nor authorized office Wi-Fi matched',
          metadata: {
            'distanceMeters': distanceMeters,
            'connectedSsid': connectedSsid,
          },
        );

      case GeofenceVerificationMode.gpsAndWifi:
        if (isGpsWithinGeofence && wifiMatched) {
          return MultiFactorPresenceResult.dualSuccess(
            distanceMeters: distanceMeters,
            ssid: connectedSsid ?? 'Office Wi-Fi',
          );
        }
        final missing = <String>[];
        if (!isGpsWithinGeofence) missing.add('GPS coordinates');
        if (!wifiMatched) missing.add('Office Wi-Fi');
        return MultiFactorPresenceResult.failure(
          'High security verification failed: ${missing.join(' and ')} not verified',
          metadata: {
            'gpsMatched': isGpsWithinGeofence,
            'wifiMatched': wifiMatched,
          },
        );
    }
  }
}
