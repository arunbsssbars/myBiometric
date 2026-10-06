import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/labor_compliance_policy.dart';

/// Enterprise Labor Law, Rest Period & Statutory Compliance Audit Service
class ComplianceAuditService {
  final FirebaseFirestore? _customFirestore;

  ComplianceAuditService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  /// Fetches the enterprise labor compliance policy
  Future<LaborCompliancePolicy> getLaborCompliancePolicy(String enterpriseId) async {
    try {
      final doc = await _firestore
          .collection('enterprises')
          .doc(enterpriseId)
          .collection('policies')
          .doc('labor_compliance')
          .get();

      if (doc.exists && doc.data() != null) {
        return LaborCompliancePolicy.fromMap(doc.data()!);
      }
    } catch (_) {}
    return LaborCompliancePolicy.defaultPolicy();
  }

  /// Streams the enterprise labor compliance policy
  Stream<LaborCompliancePolicy> streamLaborCompliancePolicy(String enterpriseId) {
    return _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('policies')
        .doc('labor_compliance')
        .snapshots()
        .map((snap) {
      if (snap.exists && snap.data() != null) {
        return LaborCompliancePolicy.fromMap(snap.data()!);
      }
      return LaborCompliancePolicy.defaultPolicy();
    });
  }

  /// Saves or updates the labor compliance policy
  Future<void> saveLaborCompliancePolicy(
      String enterpriseId, LaborCompliancePolicy policy) async {
    await _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('policies')
        .doc('labor_compliance')
        .set(policy.toMap(), SetOptions(merge: true));
  }

  /// Runs the full compliance audit across employees and attendance logs
  ComplianceAuditReport auditCompliance({
    required List<Map<String, dynamic>> roster,
    required List<Map<String, dynamic>> logs,
    LaborCompliancePolicy? policy,
    DateTime? auditDate,
  }) {
    final activePolicy = policy ?? LaborCompliancePolicy.defaultPolicy();
    final now = auditDate ?? DateTime.now();

    final List<ComplianceIncident> incidents = [];

    // Group logs by employee ID
    final Map<String, List<Map<String, dynamic>>> logsByEmployee = {};
    for (final l in logs) {
      final uid = (l['userId'] ?? l['uid'] ?? '').toString();
      if (uid.isNotEmpty) {
        logsByEmployee.putIfAbsent(uid, () => []).add(l);
      }
    }

    int inspectedEmployeesCount = roster.length;
    int inspectedLogsCount = logs.length;

    for (final member in roster) {
      final uid = (member['id'] ?? member['uid'] ?? '').toString();
      final name = member['fullName'] ?? member['name'] ?? 'Staff Member';
      final empLogs = logsByEmployee[uid] ?? [];

      if (empLogs.isEmpty) continue;

      // Group logs by date (YYYY-MM-DD)
      final Map<String, List<Map<String, dynamic>>> dailyLogs = {};
      for (final l in empLogs) {
        final dt = _parseDateTime(l['timestamp']);
        final dayKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        dailyLogs.putIfAbsent(dayKey, () => []).add(l);
      }

      final sortedDayKeys = dailyLogs.keys.toList()..sort();
      final List<_DailyShiftSummary> dailySummaries = [];

      for (final dayKey in sortedDayKeys) {
        final dayList = dailyLogs[dayKey]!;
        dayList.sort((a, b) => _parseDateTime(a['timestamp']).compareTo(_parseDateTime(b['timestamp'])));

        final firstPunch = _parseDateTime(dayList.first['timestamp']);
        final lastPunch = _parseDateTime(dayList.last['timestamp']);
        final dailyDurationHours = lastPunch.difference(firstPunch).inMinutes / 60.0;

        dailySummaries.add(_DailyShiftSummary(
          dateKey: dayKey,
          firstIn: firstPunch,
          lastOut: lastPunch,
          durationHours: dailyDurationHours,
          punchCount: dayList.length,
        ));

        // 1. Audit Daily Maximum Hours
        if (activePolicy.isEnforced && dailyDurationHours > activePolicy.maxDailyWorkHours) {
          final isViolation = dailyDurationHours >= (activePolicy.maxDailyWorkHours + 1.0);
          incidents.add(ComplianceIncident(
            id: 'INC_DAILY_${uid}_$dayKey',
            employeeId: uid,
            employeeName: name,
            issueType: ComplianceIssueType.excessiveDailyHours,
            severity: isViolation ? ComplianceSeverity.violation : ComplianceSeverity.warning,
            description: 'Worked ${dailyDurationHours.toStringAsFixed(1)}h on $dayKey exceeding statutory limit (${activePolicy.maxDailyWorkHours.toStringAsFixed(1)}h)',
            timestamp: lastPunch,
            metricValue: dailyDurationHours,
            thresholdValue: activePolicy.maxDailyWorkHours,
          ));
        }
      }

      // 2. Audit Consecutive Rest Between Shifts
      if (activePolicy.isEnforced && dailySummaries.length > 1) {
        for (int i = 0; i < dailySummaries.length - 1; i++) {
          final currentDay = dailySummaries[i];
          final nextDay = dailySummaries[i + 1];

          final restDurationHours = nextDay.firstIn.difference(currentDay.lastOut).inMinutes / 60.0;

          // If rest period is positive and less than required minRestHours
          if (restDurationHours >= 0 && restDurationHours < activePolicy.minRestHoursBetweenShifts) {
            incidents.add(ComplianceIncident(
              id: 'INC_REST_${uid}_${currentDay.dateKey}_${nextDay.dateKey}',
              employeeId: uid,
              employeeName: name,
              issueType: ComplianceIssueType.insufficientRestBetweenShifts,
              severity: ComplianceSeverity.violation,
              description: 'Only ${restDurationHours.toStringAsFixed(1)}h rest between ${currentDay.dateKey} shift end and ${nextDay.dateKey} shift start (Min: ${activePolicy.minRestHoursBetweenShifts.toStringAsFixed(1)}h)',
              timestamp: nextDay.firstIn,
              metricValue: restDurationHours,
              thresholdValue: activePolicy.minRestHoursBetweenShifts,
            ));
          }
        }
      }

      // 3. Audit Consecutive Working Days
      if (activePolicy.isEnforced && dailySummaries.length > activePolicy.maxConsecutiveWorkdays) {
        int consecutiveCount = 1;
        for (int i = 0; i < dailySummaries.length - 1; i++) {
          final d1 = dailySummaries[i].firstIn;
          final d2 = dailySummaries[i + 1].firstIn;
          final diffDays = d2.difference(d1).inDays;

          if (diffDays == 1) {
            consecutiveCount++;
            if (consecutiveCount > activePolicy.maxConsecutiveWorkdays) {
              incidents.add(ComplianceIncident(
                id: 'INC_CONSEC_${uid}_${dailySummaries[i + 1].dateKey}',
                employeeId: uid,
                employeeName: name,
                issueType: ComplianceIssueType.excessiveConsecutiveDays,
                severity: ComplianceSeverity.violation,
                description: 'Worked $consecutiveCount consecutive days without mandatory 24h rest day (Limit: ${activePolicy.maxConsecutiveWorkdays} days)',
                timestamp: dailySummaries[i + 1].firstIn,
                metricValue: consecutiveCount.toDouble(),
                thresholdValue: activePolicy.maxConsecutiveWorkdays.toDouble(),
              ));
              break; // Log once per consecutive streak
            }
          } else {
            consecutiveCount = 1;
          }
        }
      }

      // 4. Audit Weekly Hours Limit (7-day window)
      if (activePolicy.isEnforced) {
        final totalWeeklyHours = dailySummaries.fold<double>(
          0.0,
          (accumulatedHours, s) => accumulatedHours + s.durationHours,
        );

        if (totalWeeklyHours > activePolicy.maxWeeklyWorkHours) {
          incidents.add(ComplianceIncident(
            id: 'INC_WEEKLY_${uid}_${now.millisecondsSinceEpoch}',
            employeeId: uid,
            employeeName: name,
            issueType: ComplianceIssueType.excessiveWeeklyHours,
            severity: ComplianceSeverity.violation,
            description: 'Accumulated ${totalWeeklyHours.toStringAsFixed(1)}h in audit period exceeding weekly cap (${activePolicy.maxWeeklyWorkHours.toStringAsFixed(1)}h)',
            timestamp: now,
            metricValue: totalWeeklyHours,
            thresholdValue: activePolicy.maxWeeklyWorkHours,
          ));
        }
      }
    }

    final totalViolations = incidents.where((i) => i.severity == ComplianceSeverity.violation).length;
    final totalWarnings = incidents.where((i) => i.severity == ComplianceSeverity.warning).length;

    final scoreDeduction = (totalViolations * 10.0) + (totalWarnings * 3.0);
    final complianceScore = (100.0 - scoreDeduction).clamp(0.0, 100.0);

    return ComplianceAuditReport(
      generatedAt: now,
      totalInspectedEmployees: inspectedEmployeesCount,
      totalInspectedLogs: inspectedLogsCount,
      totalViolations: totalViolations,
      totalWarnings: totalWarnings,
      incidents: incidents,
      complianceScorePercent: complianceScore,
    );
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }
}

class _DailyShiftSummary {
  final String dateKey;
  final DateTime firstIn;
  final DateTime lastOut;
  final double durationHours;
  final int punchCount;

  _DailyShiftSummary({
    required this.dateKey,
    required this.firstIn,
    required this.lastOut,
    required this.durationHours,
    required this.punchCount,
  });
}
