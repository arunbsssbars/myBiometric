/// Battery management mode for background geofence monitoring
enum GeofencePowerMode {
  highPrecision, // GPS active (< 200m from branch boundary)
  balanced, // Cell-tower / Wi-Fi sampling (200m - 2000m)
  passiveLowPower, // Coarse location (> 2000m away)
}

/// Evaluation result of the proximity radar
class GeofencePowerEvaluation {
  final double distanceToNearestBranchMeters;
  final GeofencePowerMode recommendedPowerMode;
  final int recommendedLocationIntervalSeconds;
  final String nearestBranchId;

  const GeofencePowerEvaluation({
    required this.distanceToNearestBranchMeters,
    required this.recommendedPowerMode,
    required this.recommendedLocationIntervalSeconds,
    required this.nearestBranchId,
  });
}
