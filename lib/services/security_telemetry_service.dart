import '../domain/models/security_telemetry_incident.dart';

/// Autonomous security anomaly detection and SIEM event aggregation service
class SecurityTelemetryService {
  SecurityTelemetryService._internal();
  static final SecurityTelemetryService instance = SecurityTelemetryService._internal();

  /// Analyzes an incoming punch request for impossible velocity / GPS teleportation
  SecurityTelemetryIncident? detectImpossibleTravel({
    required String enterpriseId,
    required String userId,
    required double lastLat,
    required double lastLng,
    required DateTime lastTimestamp,
    required double newLat,
    required double newLng,
    required DateTime newTimestamp,
  }) {
    final diffMinutes = newTimestamp.difference(lastTimestamp).inMinutes.abs();
    if (diffMinutes <= 0) return null;

    // Approximate distance in KM using Equirectangular approximation
    final x = (newLng - lastLng) * 111.0;
    final y = (newLat - lastLat) * 111.0;
    final distanceKm = (x * x + y * y); // squared distance roughly
    final speedKmH = (distanceKm / (diffMinutes / 60.0));

    // Impossible travel: speed exceeds 900 km/h (commercial flight / GPS spoofing)
    if (speedKmH > 900.0) {
      return SecurityTelemetryIncident(
        incidentId: 'sec_${DateTime.now().millisecondsSinceEpoch}',
        enterpriseId: enterpriseId,
        userId: userId,
        incidentType: 'GEOFENCE_TELEPORT',
        severity: IncidentSeverity.critical,
        status: IncidentStatus.open,
        description: 'Impossible GPS travel detected: $speedKmH km/h across $diffMinutes mins',
        rawEvidence: {
          'lastLat': lastLat,
          'lastLng': lastLng,
          'newLat': newLat,
          'newLng': newLng,
          'speedKmH': speedKmH,
        },
        detectedAt: DateTime.now(),
      );
    }
    return null;
  }

  /// Formats incidents for enterprise SIEM Webhook dispatch (e.g. Splunk, Datadog, Elastic)
  Map<String, dynamic> formatSiemPayload(SecurityTelemetryIncident incident) {
    return {
      'event_type': 'enterprise.attendance.security_alert',
      'source': 'myBiometric-fleet',
      'severity': incident.severity.name.toUpperCase(),
      'timestamp': incident.detectedAt.toIso8601String(),
      'details': {
        'incident_id': incident.incidentId,
        'enterprise_id': incident.enterpriseId,
        'user_id': incident.userId,
        'category': incident.incidentType,
        'message': incident.description,
        'evidence': incident.rawEvidence,
      },
    };
  }
}
