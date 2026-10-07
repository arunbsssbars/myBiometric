
class ExecutiveCockpitMetrics {
  final String enterpriseId;
  final int totalTerminals;
  final int onlineTerminals;
  final double fleetUptimePercentage;
  final int totalEnrolledEmployees;
  final int currentlyOnSiteCount;
  final int activePunchesLastHour;
  final int pendingRegularizations;
  final int activeTamperAlerts;
  final double averageRecognitionConfidence;
  final DateTime aggregatedAt;

  const ExecutiveCockpitMetrics({
    required this.enterpriseId,
    required this.totalTerminals,
    required this.onlineTerminals,
    required this.fleetUptimePercentage,
    required this.totalEnrolledEmployees,
    required this.currentlyOnSiteCount,
    required this.activePunchesLastHour,
    required this.pendingRegularizations,
    required this.activeTamperAlerts,
    required this.averageRecognitionConfidence,
    required this.aggregatedAt,
  });

  bool get isFleetHealthy => fleetUptimePercentage >= 95.0 && activeTamperAlerts == 0;

  Map<String, dynamic> toJson() => {
    'enterpriseId': enterpriseId,
    'totalTerminals': totalTerminals,
    'onlineTerminals': onlineTerminals,
    'fleetUptimePercentage': fleetUptimePercentage,
    'totalEnrolledEmployees': totalEnrolledEmployees,
    'currentlyOnSiteCount': currentlyOnSiteCount,
    'activePunchesLastHour': activePunchesLastHour,
    'pendingRegularizations': pendingRegularizations,
    'activeTamperAlerts': activeTamperAlerts,
    'averageRecognitionConfidence': averageRecognitionConfidence,
    'aggregatedAt': aggregatedAt.toIso8601String(),
  };

  factory ExecutiveCockpitMetrics.fromJson(Map<String, dynamic> json) {
    return ExecutiveCockpitMetrics(
      enterpriseId: json['enterpriseId'] as String? ?? '',
      totalTerminals: (json['totalTerminals'] as num?)?.toInt() ?? 0,
      onlineTerminals: (json['onlineTerminals'] as num?)?.toInt() ?? 0,
      fleetUptimePercentage: (json['fleetUptimePercentage'] as num?)?.toDouble() ?? 100.0,
      totalEnrolledEmployees: (json['totalEnrolledEmployees'] as num?)?.toInt() ?? 0,
      currentlyOnSiteCount: (json['currentlyOnSiteCount'] as num?)?.toInt() ?? 0,
      activePunchesLastHour: (json['activePunchesLastHour'] as num?)?.toInt() ?? 0,
      pendingRegularizations: (json['pendingRegularizations'] as num?)?.toInt() ?? 0,
      activeTamperAlerts: (json['activeTamperAlerts'] as num?)?.toInt() ?? 0,
      averageRecognitionConfidence: (json['averageRecognitionConfidence'] as num?)?.toDouble() ?? 0.95,
      aggregatedAt: DateTime.tryParse(json['aggregatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ExecutiveCommandCenterService {
  static final ExecutiveCommandCenterService _instance = ExecutiveCommandCenterService._internal();
  factory ExecutiveCommandCenterService() => _instance;
  ExecutiveCommandCenterService._internal();

  ExecutiveCockpitMetrics synthesizeMetrics({
    required String enterpriseId,
    required int totalTerminals,
    required int onlineTerminals,
    required int totalEmployees,
    required int onSiteEmployees,
    required int punchesLastHour,
    required int pendingRegularizations,
    required int tamperAlerts,
    double averageConfidence = 0.96,
  }) {
    final uptime = totalTerminals > 0 
        ? ((onlineTerminals / totalTerminals) * 100.0).clamp(0.0, 100.0) 
        : 100.0;

    return ExecutiveCockpitMetrics(
      enterpriseId: enterpriseId,
      totalTerminals: totalTerminals,
      onlineTerminals: onlineTerminals,
      fleetUptimePercentage: uptime,
      totalEnrolledEmployees: totalEmployees,
      currentlyOnSiteCount: onSiteEmployees,
      activePunchesLastHour: punchesLastHour,
      pendingRegularizations: pendingRegularizations,
      activeTamperAlerts: tamperAlerts,
      averageRecognitionConfidence: averageConfidence,
      aggregatedAt: DateTime.now(),
    );
  }
}
