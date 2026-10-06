import 'dart:math' as math;

/// Represents an enterprise branch, office location, or facility zone.
class EnterpriseBranch {
  final String id;
  final String enterpriseId;
  final String name;
  final String code;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final List<String> allowedWifiSsids;
  final List<String> assignedTerminalIds;
  final bool isActive;
  final String? timezone;
  final DateTime createdAt;

  const EnterpriseBranch({
    String? id,
    String? branchId,
    required this.enterpriseId,
    required this.name,
    required this.code,
    this.address = 'Office Location',
    required this.latitude,
    required this.longitude,
    double? radiusMeters,
    double? geofenceRadiusMeters,
    this.allowedWifiSsids = const [],
    this.assignedTerminalIds = const [],
    this.isActive = true,
    this.timezone,
    required this.createdAt,
  })  : id = id ?? branchId ?? '',
        radiusMeters = radiusMeters ?? geofenceRadiusMeters ?? 150.0;

  /// Compatibility alias for id
  String get branchId => id;

  /// Compatibility alias for radiusMeters
  double get geofenceRadiusMeters => radiusMeters;

  /// Calculate distance in meters to a given coordinate using Haversine formula
  double distanceMetersTo(double targetLat, double targetLng) {
    const double earthRadiusMeters = 6371000.0;
    final dLat = (targetLat - latitude) * (math.pi / 180.0);
    final dLon = (targetLng - longitude) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitude * (math.pi / 180.0)) *
            math.cos(targetLat * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branchId': id,
    'enterpriseId': enterpriseId,
    'name': name,
    'code': code,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'geofenceRadiusMeters': radiusMeters,
    'allowedWifiSsids': allowedWifiSsids,
    'assignedTerminalIds': assignedTerminalIds,
    'isActive': isActive,
    'timezone': timezone,
    'createdAt': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toMap() => toJson();

  factory EnterpriseBranch.fromJson(Map<String, dynamic> map) {
    return EnterpriseBranch(
      id: map['id'] as String? ?? map['branchId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Branch',
      code: map['code'] as String? ?? 'HQ',
      address: map['address'] as String? ?? 'Office Location',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ??
          (map['geofenceRadiusMeters'] as num?)?.toDouble() ??
          150.0,
      allowedWifiSsids: List<String>.from(map['allowedWifiSsids'] as List? ?? []),
      assignedTerminalIds: List<String>.from(map['assignedTerminalIds'] as List? ?? []),
      isActive: map['isActive'] as bool? ?? true,
      timezone: map['timezone'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory EnterpriseBranch.fromFirestore(dynamic doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return EnterpriseBranch.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  factory EnterpriseBranch.fromMap(Map<String, dynamic> map) => EnterpriseBranch.fromJson(map);
}

/// Evaluation result when checking an employee against multi-branch geofences.
class BranchGeofenceEvaluation {
  final EnterpriseBranch? matchedBranch;
  final double distanceMeters;
  final bool isWithinGeofence;
  final bool isAuthorizedForEmployee;
  final String reason;

  const BranchGeofenceEvaluation({
    this.matchedBranch,
    required this.distanceMeters,
    required this.isWithinGeofence,
    required this.isAuthorizedForEmployee,
    required this.reason,
  });
}
