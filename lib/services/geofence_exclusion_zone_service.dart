
class GeoCoordinate {
  final double latitude;
  final double longitude;

  const GeoCoordinate({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) {
    return GeoCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class ExclusionPolygonZone {
  final String id;
  final String enterpriseId;
  final String branchId;
  final String name;
  final String reason; // e.g. "Construction Area", "Parking Lot", "Restricted Vault"
  final List<GeoCoordinate> vertices;
  final bool isActive;
  final DateTime createdAt;

  const ExclusionPolygonZone({
    required this.id,
    required this.enterpriseId,
    required this.branchId,
    required this.name,
    required this.reason,
    required this.vertices,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'enterpriseId': enterpriseId,
    'branchId': branchId,
    'name': name,
    'reason': reason,
    'vertices': vertices.map((v) => v.toJson()).toList(),
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ExclusionPolygonZone.fromJson(Map<String, dynamic> json) {
    return ExclusionPolygonZone(
      id: json['id'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      name: json['name'] as String? ?? 'Exclusion Zone',
      reason: json['reason'] as String? ?? 'Restricted Area',
      vertices: (json['vertices'] as List<dynamic>? ?? [])
          .map((v) => GeoCoordinate.fromJson(v as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Ray-casting algorithm to test whether a given point lies inside the polygon
  bool containsPoint(GeoCoordinate point) {
    if (vertices.length < 3) return false;

    bool inside = false;
    int j = vertices.length - 1;

    for (int i = 0; i < vertices.length; i++) {
      final vi = vertices[i];
      final vj = vertices[j];

      final intersect = ((vi.latitude > point.latitude) != (vj.latitude > point.latitude)) &&
          (point.longitude < (vj.longitude - vi.longitude) * (point.latitude - vi.latitude) / (vj.latitude - vi.latitude) + vi.longitude);

      if (intersect) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }
}

class ExclusionZoneViolationEvent {
  final String id;
  final String userId;
  final String employeeName;
  final String zoneId;
  final String zoneName;
  final GeoCoordinate coordinate;
  final DateTime timestamp;

  const ExclusionZoneViolationEvent({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.zoneId,
    required this.zoneName,
    required this.coordinate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'employeeName': employeeName,
    'zoneId': zoneId,
    'zoneName': zoneName,
    'coordinate': coordinate.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
}

class GeofenceExclusionZoneService {
  static final GeofenceExclusionZoneService _instance = GeofenceExclusionZoneService._internal();
  factory GeofenceExclusionZoneService() => _instance;
  GeofenceExclusionZoneService._internal();

  final List<ExclusionPolygonZone> _zones = [];
  final List<ExclusionZoneViolationEvent> _violations = [];

  List<ExclusionPolygonZone> get zones => List.unmodifiable(_zones);
  List<ExclusionZoneViolationEvent> get violations => List.unmodifiable(_violations);

  void registerZone(ExclusionPolygonZone zone) {
    _zones.removeWhere((z) => z.id == zone.id);
    _zones.add(zone);
  }

  void removeZone(String zoneId) {
    _zones.removeWhere((z) => z.id == zoneId);
  }

  /// Evaluates whether coordinates fall inside an active exclusion zone
  ExclusionPolygonZone? findViolatedExclusionZone({
    required String enterpriseId,
    required double latitude,
    required double longitude,
  }) {
    final point = GeoCoordinate(latitude: latitude, longitude: longitude);
    for (final zone in _zones) {
      if (zone.enterpriseId == enterpriseId && zone.isActive) {
        if (zone.containsPoint(point)) {
          return zone;
        }
      }
    }
    return null;
  }

  ExclusionZoneViolationEvent recordViolation({
    required String userId,
    required String employeeName,
    required ExclusionPolygonZone zone,
    required double latitude,
    required double longitude,
  }) {
    final violation = ExclusionZoneViolationEvent(
      id: 'viol_${DateTime.now().millisecondsSinceEpoch}_${_violations.length}',
      userId: userId,
      employeeName: employeeName,
      zoneId: zone.id,
      zoneName: zone.name,
      coordinate: GeoCoordinate(latitude: latitude, longitude: longitude),
      timestamp: DateTime.now(),
    );
    _violations.insert(0, violation);
    return violation;
  }

  void clearForTesting() {
    _zones.clear();
    _violations.clear();
  }
}
