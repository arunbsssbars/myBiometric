/// Modes for multi-factor office geofencing (Jibble-compliant)
enum GeofenceVerificationMode {
  gpsOnly,
  wifiOnly,
  gpsOrWifi, // Pass if either GPS or Wi-Fi is verified (recommended for enterprise)
  gpsAndWifi, // Both GPS and Wi-Fi must match (high security)
}

/// Model defining office Wi-Fi and IP geofencing rules for an enterprise site
class NetworkGeofencePolicy {
  final bool isWifiGeofenceEnabled;
  final bool isIpWhitelistEnabled;
  final GeofenceVerificationMode mode;
  final List<String> allowedSsids;
  final List<String> allowedBssids; // MAC addresses of authorized access points
  final List<String> allowedIpSubnets; // e.g., ["192.168.1.", "10.0.0."]

  const NetworkGeofencePolicy({
    this.isWifiGeofenceEnabled = false,
    this.isIpWhitelistEnabled = false,
    this.mode = GeofenceVerificationMode.gpsOrWifi,
    this.allowedSsids = const [],
    this.allowedBssids = const [],
    this.allowedIpSubnets = const [],
  });

  factory NetworkGeofencePolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NetworkGeofencePolicy();

    GeofenceVerificationMode parsedMode = GeofenceVerificationMode.gpsOrWifi;
    final modeStr = json['mode'] as String?;
    if (modeStr != null) {
      for (final m in GeofenceVerificationMode.values) {
        if (m.name == modeStr) {
          parsedMode = m;
          break;
        }
      }
    }

    return NetworkGeofencePolicy(
      isWifiGeofenceEnabled: json['isWifiGeofenceEnabled'] as bool? ?? false,
      isIpWhitelistEnabled: json['isIpWhitelistEnabled'] as bool? ?? false,
      mode: parsedMode,
      allowedSsids: (json['allowedSsids'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      allowedBssids: (json['allowedBssids'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? const [],
      allowedIpSubnets: (json['allowedIpSubnets'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'isWifiGeofenceEnabled': isWifiGeofenceEnabled,
        'isIpWhitelistEnabled': isIpWhitelistEnabled,
        'mode': mode.name,
        'allowedSsids': allowedSsids,
        'allowedBssids': allowedBssids,
        'allowedIpSubnets': allowedIpSubnets,
      };

  NetworkGeofencePolicy copyWith({
    bool? isWifiGeofenceEnabled,
    bool? isIpWhitelistEnabled,
    GeofenceVerificationMode? mode,
    List<String>? allowedSsids,
    List<String>? allowedBssids,
    List<String>? allowedIpSubnets,
  }) {
    return NetworkGeofencePolicy(
      isWifiGeofenceEnabled: isWifiGeofenceEnabled ?? this.isWifiGeofenceEnabled,
      isIpWhitelistEnabled: isIpWhitelistEnabled ?? this.isIpWhitelistEnabled,
      mode: mode ?? this.mode,
      allowedSsids: allowedSsids ?? this.allowedSsids,
      allowedBssids: allowedBssids ?? this.allowedBssids,
      allowedIpSubnets: allowedIpSubnets ?? this.allowedIpSubnets,
    );
  }
}
