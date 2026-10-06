import '../domain/models/evacuation_roster.dart';

/// Service for generating live building evacuation roll-call sheets and tracking headcounts
class EvacuationRollcallService {
  /// Builds roll-call roster of all employees currently clocked IN
  static List<EvacueeStatus> buildRollcallList({
    required List<Map<String, dynamic>> activeSessions,
  }) {
    final list = <EvacueeStatus>[];

    for (final s in activeSessions) {
      final isClockedIn = s['isClockedIn'] as bool? ?? false;
      if (!isClockedIn) continue;

      final uid = s['userId'] as String? ?? '';
      final name = s['employeeName'] as String? ?? 'Employee';
      final dept = s['department'] as String? ?? 'General';
      final location = s['lastLocation'] as String? ?? 'Main Office';
      final rawTs = s['lastPunchTime'];
      DateTime ts = DateTime.now();
      if (rawTs is DateTime) ts = rawTs;
      if (rawTs is String) ts = DateTime.tryParse(rawTs) ?? DateTime.now();

      list.add(
        EvacueeStatus(
          userId: uid,
          employeeName: name,
          department: dept,
          lastKnownLocation: location,
          lastPunchTime: ts,
          isAccountedFor: false,
        ),
      );
    }

    return list;
  }

  /// Calculates real-time evacuation headcount summary
  static EvacuationSummary calculateSummary(List<EvacueeStatus> evacuees) {
    final total = evacuees.length;
    final accounted = evacuees.where((e) => e.isAccountedFor).length;
    final missing = total - accounted;
    final percent = total > 0 ? (accounted / total) * 100.0 : 100.0;

    return EvacuationSummary(
      totalOnSite: total,
      totalAccountedFor: accounted,
      totalMissing: missing,
      accountedForPercent: percent,
    );
  }
}
