import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/enterprise_branch.dart';

/// Result of evaluating location proximity across multiple enterprise branches.
class BranchProximityResult {
  final bool isWithinAnyBranch;
  final EnterpriseBranch? matchingBranch;
  final double distanceMeters;
  final bool verifiedViaWifi;
  final String statusMessage;

  const BranchProximityResult({
    required this.isWithinAnyBranch,
    this.matchingBranch,
    this.distanceMeters = 0.0,
    this.verifiedViaWifi = false,
    required this.statusMessage,
  });
}

/// Service managing multi-branch and multi-location physical sites, geofences, and SSIDs.
class BranchLocationService {
  final FirebaseFirestore? _firestore;

  BranchLocationService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _effectiveFirestore {
    return _firestore ?? FirebaseFirestore.instance;
  }

  /// Finds the closest branch to the employee and evaluates geofence/Wi-Fi compliance.
  static BranchProximityResult evaluateLocation({
    required List<EnterpriseBranch> branches,
    required double userLat,
    required double userLng,
    String? connectedWifiSsid,
  }) {
    if (branches.isEmpty) {
      return const BranchProximityResult(
        isWithinAnyBranch: true, // If no branch is restricted, allow open geofence
        statusMessage: 'No branch geofences configured. Defaulting to authorized.',
      );
    }

    EnterpriseBranch? closestBranch;
    double minDistance = double.infinity;

    for (final branch in branches) {
      if (!branch.isActive) continue;

      // Check Wi-Fi SSID match first
      if (connectedWifiSsid != null && connectedWifiSsid.isNotEmpty) {
        final normalizedSsid = connectedWifiSsid.trim().toLowerCase();
        final matchesWifi = branch.allowedWifiSsids.any(
          (s) => s.trim().toLowerCase() == normalizedSsid,
        );
        if (matchesWifi) {
          final dist = branch.distanceMetersTo(userLat, userLng);
          return BranchProximityResult(
            isWithinAnyBranch: true,
            matchingBranch: branch,
            distanceMeters: dist,
            verifiedViaWifi: true,
            statusMessage: 'Authorized via branch Wi-Fi (${branch.name}).',
          );
        }
      }

      final dist = branch.distanceMetersTo(userLat, userLng);
      if (dist < minDistance) {
        minDistance = dist;
        closestBranch = branch;
      }
    }

    if (closestBranch != null && minDistance <= closestBranch.radiusMeters) {
      return BranchProximityResult(
        isWithinAnyBranch: true,
        matchingBranch: closestBranch,
        distanceMeters: minDistance,
        verifiedViaWifi: false,
        statusMessage: 'Authorized at ${closestBranch.name} (${minDistance.toStringAsFixed(0)}m from center).',
      );
    }

    final branchName = closestBranch?.name ?? 'Branch';
    return BranchProximityResult(
      isWithinAnyBranch: false,
      matchingBranch: closestBranch,
      distanceMeters: minDistance,
      verifiedViaWifi: false,
      statusMessage: 'Outside authorized perimeter ($branchName is ${minDistance.toStringAsFixed(0)}m away).',
    );
  }

  /// Streams active branches for an enterprise.
  Stream<List<EnterpriseBranch>> streamBranches(String enterpriseId) {
    return _effectiveFirestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('branches')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => EnterpriseBranch.fromFirestore(doc)).toList());
  }

  /// Saves or updates a branch in Firestore.
  Future<void> saveBranch(String enterpriseId, EnterpriseBranch branch) async {
    final ref = _effectiveFirestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('branches')
        .doc(branch.id.isNotEmpty ? branch.id : null);

    await ref.set(branch.toJson(), SetOptions(merge: true));
  }

  /// Deletes a branch from Firestore.
  Future<void> deleteBranch(String enterpriseId, String branchId) async {
    await _effectiveFirestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('branches')
        .doc(branchId)
        .delete();
  }
}
