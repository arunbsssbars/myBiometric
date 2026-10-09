
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<ExecutiveCockpitMetrics> fetchLiveMetrics(String enterpriseId) async {
    int totalTerminals = 0;
    int onlineTerminals = 0;
    int totalEmployees = 0;
    int onSiteEmployees = 0;
    int punchesLastHour = 0;
    int pendingRegularizations = 0;
    int tamperAlerts = 0;

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final startOfToday = DateTime(now.year, now.month, now.day);

    try {
      final devSnap = await FirebaseFirestore.instance
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('devices')
          .get();
      totalTerminals = devSnap.docs.length;
      onlineTerminals = devSnap.docs.where((d) => d.data()['status'] == 'online').length;
    } catch (_) {}

    try {
      final empSnap = await FirebaseFirestore.instance
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('employees')
          .get();
      totalEmployees = empSnap.docs.length;
    } catch (_) {}

    try {
      final logSnap = await FirebaseFirestore.instance
          .collection('attendance_logs')
          .where('enterpriseId', isEqualTo: enterpriseId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .get();

      final inUsers = <String>{};
      final outUsers = <String>{};

      for (final doc in logSnap.docs) {
        final data = doc.data();
        final uid = data['userId']?.toString() ?? '';
        final type = data['type']?.toString();
        final ts = (data['timestamp'] as Timestamp?)?.toDate();

        if (ts != null && ts.isAfter(oneHourAgo)) {
          punchesLastHour++;
        }

        if (type == 'PUNCH_IN') {
          inUsers.add(uid);
        } else if (type == 'PUNCH_OUT') {
          outUsers.add(uid);
        }
      }

      onSiteEmployees = inUsers.difference(outUsers).length;
    } catch (_) {}

    try {
      final regSnap = await FirebaseFirestore.instance
          .collection('approval_requests')
          .where('enterpriseId', isEqualTo: enterpriseId)
          .where('status', isEqualTo: 'PENDING')
          .get();
      pendingRegularizations = regSnap.docs.length;
    } catch (_) {}

    return synthesizeMetrics(
      enterpriseId: enterpriseId,
      totalTerminals: totalTerminals,
      onlineTerminals: onlineTerminals,
      totalEmployees: totalEmployees,
      onSiteEmployees: onSiteEmployees,
      punchesLastHour: punchesLastHour,
      pendingRegularizations: pendingRegularizations,
      tamperAlerts: tamperAlerts,
    );
  }
}
