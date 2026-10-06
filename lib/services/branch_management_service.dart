import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/enterprise_branch.dart';

/// Enterprise Multi-Branch Management & Geofencing Resolver
class BranchManagementService {
  final FirebaseFirestore? _firestore;

  BranchManagementService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _effectiveFirestore =>
      _firestore ?? FirebaseFirestore.instance;

  /// Calculate Haversine distance in meters between two GPS coordinates
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);

  /// Find the nearest branch from a given coordinate among active branches
  static EnterpriseBranch? findNearestBranch({
    required List<EnterpriseBranch> branches,
    required double latitude,
    required double longitude,
  }) {
    final active = branches.where((b) => b.isActive).toList();
    if (active.isEmpty) return null;

    EnterpriseBranch? nearest;
    double minDistance = double.infinity;

    for (final branch in active) {
      final dist = calculateDistanceMeters(
        lat1: latitude,
        lon1: longitude,
        lat2: branch.latitude,
        lon2: branch.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = branch;
      }
    }
    return nearest;
  }

  /// Evaluates an employee's coordinates against branches
  static BranchGeofenceEvaluation evaluateLocation({
    required List<EnterpriseBranch> branches,
    required double latitude,
    required double longitude,
    List<String> employeeAssignedBranchIds = const [],
    bool allowAllBranchesIfUnassigned = true,
  }) {
    final active = branches.where((b) => b.isActive).toList();
    if (active.isEmpty) {
      return const BranchGeofenceEvaluation(
        matchedBranch: null,
        distanceMeters: double.infinity,
        isWithinGeofence: false,
        isAuthorizedForEmployee: false,
        reason: 'No active enterprise branches configured',
      );
    }

    EnterpriseBranch? bestMatch;
    double bestDistance = double.infinity;

    for (final branch in active) {
      final dist = calculateDistanceMeters(
        lat1: latitude,
        lon1: longitude,
        lat2: branch.latitude,
        lon2: branch.longitude,
      );
      if (dist < bestDistance) {
        bestDistance = dist;
        bestMatch = branch;
      }
    }

    if (bestMatch == null) {
      return const BranchGeofenceEvaluation(
        matchedBranch: null,
        distanceMeters: double.infinity,
        isWithinGeofence: false,
        isAuthorizedForEmployee: false,
        reason: 'Unable to evaluate coordinates',
      );
    }

    final isWithinRadius = bestDistance <= bestMatch.radiusMeters;

    final isAuthorized = employeeAssignedBranchIds.isEmpty
        ? allowAllBranchesIfUnassigned
        : employeeAssignedBranchIds.contains(bestMatch.id);

    String reason;
    if (!isWithinRadius) {
      reason = 'Outside geofence of nearest branch ${bestMatch.name} (${bestDistance.toStringAsFixed(1)}m > ${bestMatch.radiusMeters.toStringAsFixed(0)}m)';
    } else if (!isAuthorized) {
      reason = 'Within ${bestMatch.name} geofence, but employee is not authorized for this branch';
    } else {
      reason = 'Authorized at ${bestMatch.name} (${bestDistance.toStringAsFixed(1)}m from center)';
    }

    return BranchGeofenceEvaluation(
      matchedBranch: bestMatch,
      distanceMeters: bestDistance,
      isWithinGeofence: isWithinRadius,
      isAuthorizedForEmployee: isAuthorized,
      reason: reason,
    );
  }

  /// Verifies if a connected Wi-Fi SSID matches any allowed SSID in the branch
  static bool verifyBranchWifi({
    required EnterpriseBranch branch,
    required String? currentSsid,
  }) {
    if (branch.allowedWifiSsids.isEmpty) return true;
    if (currentSsid == null || currentSsid.isEmpty) return false;
    final normalized = currentSsid.replaceAll('"', '').trim().toLowerCase();
    return branch.allowedWifiSsids.any(
      (ssid) => ssid.replaceAll('"', '').trim().toLowerCase() == normalized,
    );
  }

  /// Streams active branches for an enterprise from Firestore
  Stream<List<EnterpriseBranch>> getEnterpriseBranches(String enterpriseId) {
    return _effectiveFirestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('branches')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EnterpriseBranch.fromFirestore(doc)).toList());
  }

  /// Saves or updates a branch in Firestore
  Future<void> saveBranch({
    required String enterpriseId,
    required EnterpriseBranch branch,
  }) async {
    final col = _effectiveFirestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('branches');

    final docRef = branch.id.isNotEmpty ? col.doc(branch.id) : col.doc();
    final data = branch.toJson();
    data['id'] = docRef.id;
    await docRef.set(data, SetOptions(merge: true));
  }

  /// Deletes a branch from Firestore
  Future<void> deleteBranch({
    required String enterpriseId,
    required String branchId,
    String? branchName,
  }) async {
    await _effectiveFirestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('branches')
        .doc(branchId)
        .delete();
  }
}
