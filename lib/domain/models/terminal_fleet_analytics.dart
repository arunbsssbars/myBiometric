/// Hourly throughput distribution bucket for hardware biometric machines.
class TerminalThroughputBucket {
  final int hourOfDay; // 0 - 23
  final int totalPunches;
  final int faceMatches;
  final int cardSwipes;
  final int securityRejections;

  const TerminalThroughputBucket({
    required this.hourOfDay,
    this.totalPunches = 0,
    this.faceMatches = 0,
    this.cardSwipes = 0,
    this.securityRejections = 0,
  });

  String get hourLabel => '${hourOfDay.toString().padLeft(2, '0')}:00';

  Map<String, dynamic> toJson() {
    return {
      'hourOfDay': hourOfDay,
      'totalPunches': totalPunches,
      'faceMatches': faceMatches,
      'cardSwipes': cardSwipes,
      'securityRejections': securityRejections,
    };
  }

  factory TerminalThroughputBucket.fromJson(Map<String, dynamic> json) {
    return TerminalThroughputBucket(
      hourOfDay: (json['hourOfDay'] as num?)?.toInt() ?? 0,
      totalPunches: (json['totalPunches'] as num?)?.toInt() ?? 0,
      faceMatches: (json['faceMatches'] as num?)?.toInt() ?? 0,
      cardSwipes: (json['cardSwipes'] as num?)?.toInt() ?? 0,
      securityRejections: (json['securityRejections'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Comprehensive analytics and SLA availability scoreboard report for the terminal fleet.
class TerminalFleetAnalyticsReport {
  final String enterpriseId;
  final int totalTerminals;
  final int onlineTerminals;
  final double fleetUptimePercent; // e.g. 99.8
  final int totalPunchesToday;
  final int peakHour; // e.g. 9 (09:00 AM)
  final int peakHourPunchCount;
  final double averageFaceSimilarityScore;
  final List<TerminalThroughputBucket> hourlyThroughput;
  final DateTime generatedAt;

  const TerminalFleetAnalyticsReport({
    required this.enterpriseId,
    required this.totalTerminals,
    required this.onlineTerminals,
    required this.fleetUptimePercent,
    required this.totalPunchesToday,
    required this.peakHour,
    required this.peakHourPunchCount,
    required this.averageFaceSimilarityScore,
    required this.hourlyThroughput,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'enterpriseId': enterpriseId,
      'totalTerminals': totalTerminals,
      'onlineTerminals': onlineTerminals,
      'fleetUptimePercent': fleetUptimePercent,
      'totalPunchesToday': totalPunchesToday,
      'peakHour': peakHour,
      'peakHourPunchCount': peakHourPunchCount,
      'averageFaceSimilarityScore': averageFaceSimilarityScore,
      'hourlyThroughput': hourlyThroughput.map((b) => b.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory TerminalFleetAnalyticsReport.fromJson(Map<String, dynamic> json) {
    return TerminalFleetAnalyticsReport(
      enterpriseId: json['enterpriseId'] as String? ?? '',
      totalTerminals: (json['totalTerminals'] as num?)?.toInt() ?? 0,
      onlineTerminals: (json['onlineTerminals'] as num?)?.toInt() ?? 0,
      fleetUptimePercent: (json['fleetUptimePercent'] as num?)?.toDouble() ?? 100.0,
      totalPunchesToday: (json['totalPunchesToday'] as num?)?.toInt() ?? 0,
      peakHour: (json['peakHour'] as num?)?.toInt() ?? 9,
      peakHourPunchCount: (json['peakHourPunchCount'] as num?)?.toInt() ?? 0,
      averageFaceSimilarityScore: (json['averageFaceSimilarityScore'] as num?)?.toDouble() ?? 99.2,
      hourlyThroughput: (json['hourlyThroughput'] as List<dynamic>?)
              ?.map((e) => TerminalThroughputBucket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
