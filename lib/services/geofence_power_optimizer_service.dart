import '../domain/models/enterprise_branch.dart';
import '../domain/models/geofence_power_mode.dart';

/// Service for calculating distance-based GPS polling frequency to save battery
class GeofencePowerOptimizerService {
  /// Evaluates distance to all company branches and calculates optimal battery mode
  static GeofencePowerEvaluation evaluatePowerMode({
    required double userLat,
    required double userLng,
    required List<EnterpriseBranch> branches,
  }) {
    if (branches.isEmpty) {
      return const GeofencePowerEvaluation(
        distanceToNearestBranchMeters: double.infinity,
        recommendedPowerMode: GeofencePowerMode.passiveLowPower,
        recommendedLocationIntervalSeconds: 300, // 5 mins
        nearestBranchId: '',
      );
    }

    EnterpriseBranch nearest = branches.first;
    double minDistance = double.infinity;

    for (final branch in branches) {
      final dist = branch.distanceMetersTo(userLat, userLng);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = branch;
      }
    }

    if (minDistance <= (nearest.radiusMeters + 200)) {
      return GeofencePowerEvaluation(
        distanceToNearestBranchMeters: minDistance,
        recommendedPowerMode: GeofencePowerMode.highPrecision,
        recommendedLocationIntervalSeconds: 10,
        nearestBranchId: nearest.id,
      );
    } else if (minDistance <= 2000) {
      return GeofencePowerEvaluation(
        distanceToNearestBranchMeters: minDistance,
        recommendedPowerMode: GeofencePowerMode.balanced,
        recommendedLocationIntervalSeconds: 60,
        nearestBranchId: nearest.id,
      );
    } else {
      return GeofencePowerEvaluation(
        distanceToNearestBranchMeters: minDistance,
        recommendedPowerMode: GeofencePowerMode.passiveLowPower,
        recommendedLocationIntervalSeconds: 300,
        nearestBranchId: nearest.id,
      );
    }
  }
}
