import 'package:flutter/foundation.dart';

enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

enum IncidentStatus {
  open,
  investigating,
  mitigated,
  resolved,
  falsePositive,
}

/// Incident record raised during enterprise security telemetry anomaly detection
@immutable
class SecurityTelemetryIncident {
  final String incidentId;
  final String enterpriseId;
  final String? deviceId;
  final String? userId;
  final String incidentType; // 'SPOOF_INJECTION', 'GEOFENCE_TELEPORT', 'RAPID_DEVICE_SWITCH', 'BRUTE_FORCE_PIN'
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String description;
  final Map<String, dynamic> rawEvidence;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  const SecurityTelemetryIncident({
    required this.incidentId,
    required this.enterpriseId,
    this.deviceId,
    this.userId,
    required this.incidentType,
    required this.severity,
    required this.status,
    required this.description,
    this.rawEvidence = const {},
    required this.detectedAt,
    this.resolvedAt,
  });

  bool get isActionRequired =>
      status == IncidentStatus.open || status == IncidentStatus.investigating;

  SecurityTelemetryIncident copyWith({
    String? incidentId,
    String? enterpriseId,
    String? deviceId,
    String? userId,
    String? incidentType,
    IncidentSeverity? severity,
    IncidentStatus? status,
    String? description,
    Map<String, dynamic>? rawEvidence,
    DateTime? detectedAt,
    DateTime? resolvedAt,
  }) {
    return SecurityTelemetryIncident(
      incidentId: incidentId ?? this.incidentId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      incidentType: incidentType ?? this.incidentType,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      rawEvidence: rawEvidence ?? this.rawEvidence,
      detectedAt: detectedAt ?? this.detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'incidentId': incidentId,
        'enterpriseId': enterpriseId,
        'deviceId': deviceId,
        'userId': userId,
        'incidentType': incidentType,
        'severity': severity.name,
        'status': status.name,
        'description': description,
        'rawEvidence': rawEvidence,
        'detectedAt': detectedAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory SecurityTelemetryIncident.fromMap(Map<String, dynamic> map) =>
      SecurityTelemetryIncident(
        incidentId: map['incidentId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        deviceId: map['deviceId'] as String?,
        userId: map['userId'] as String?,
        incidentType: map['incidentType'] as String? ?? 'ANOMALY',
        severity: IncidentSeverity.values.firstWhere(
          (e) => e.name == map['severity'],
          orElse: () => IncidentSeverity.medium,
        ),
        status: IncidentStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => IncidentStatus.open,
        ),
        description: map['description'] as String? ?? '',
        rawEvidence: (map['rawEvidence'] as Map<String, dynamic>?) ?? {},
        detectedAt: map['detectedAt'] != null
            ? DateTime.tryParse(map['detectedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        resolvedAt: map['resolvedAt'] != null
            ? DateTime.tryParse(map['resolvedAt'] as String)
            : null,
      );
}
