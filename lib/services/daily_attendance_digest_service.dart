import '../domain/models/daily_attendance_digest.dart';
import '../core/utils/app_format_utils.dart';

/// Service generating automated enterprise attendance digests and operational anomaly feeds
class DailyAttendanceDigestService {
  /// Compiles a comprehensive daily attendance digest
  static DailyAttendanceDigest generateDailyDigest({
    required DateTime date,
    required List<Map<String, dynamic>> roster,
    required List<Map<String, dynamic>> logs,
    List<Map<String, dynamic>> approvedLeaves = const [],
    DateTime? evaluationTime,
  }) {
    final now = evaluationTime ?? DateTime.now();
    final totalHeadcount = roster.length;

    // Group logs by userId
    final Map<String, List<Map<String, dynamic>>> logsByUser = {};
    for (final l in logs) {
      final uid = (l['userId'] ?? l['uid'] ?? '').toString();
      if (uid.isNotEmpty) {
        logsByUser.putIfAbsent(uid, () => []).add(l);
      }
    }

    // Set of userIds on approved leave
    final leaveUserIds = approvedLeaves
        .map((l) => (l['userId'] ?? l['uid'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    int presentCount = 0;
    int lateCount = 0;
    int unclosedShiftsCount = 0;
    int overstayedBreaksCount = 0;
    double totalOvertimeMinutes = 0.0;
    final List<String> anomalies = [];

    for (final member in roster) {
      final uid = (member['id'] ?? member['uid'] ?? '').toString();
      final name = member['fullName'] ?? member['name'] ?? 'Staff Member';
      final userLogs = logsByUser[uid] ?? [];

      if (userLogs.isNotEmpty) {
        presentCount++;

        // Sort chronologically
        userLogs.sort((a, b) {
          final ta = _parseTimestamp(a['timestamp']);
          final tb = _parseTimestamp(b['timestamp']);
          return ta.compareTo(tb);
        });

        final firstPunch = userLogs.first;
        final latestPunch = userLogs.last;

        // Late check
        final pStatus = firstPunch['punchStatus']?.toString();
        final lateMins = (firstPunch['lateMinutes'] as num?)?.toInt() ?? 0;
        if (pStatus == 'LATE_ARRIVAL' || lateMins > 0) {
          lateCount++;
        }

        // Sum overtime
        for (final l in userLogs) {
          if (l['overtimeMinutes'] != null) {
            totalOvertimeMinutes += (l['overtimeMinutes'] as num).toDouble();
          }
        }

        // Check for unclosed shifts at end of day
        final latestType = latestPunch['type']?.toString();
        if (latestType == 'PUNCH_IN' || latestType == 'END_BREAK') {
          // If evaluation is after 18:00 (6 PM) or next day, flag unclosed shift
          if (now.hour >= 18 || now.day != date.day) {
            unclosedShiftsCount++;
            anomalies.add('$name: Missing clock-out (last active at ${_formatTime(_parseTimestamp(latestPunch['timestamp']))})');
          }
        } else if (latestType == 'START_BREAK') {
          // Flag employee currently left on break
          final breakStart = _parseTimestamp(latestPunch['timestamp']);
          final breakDurationMins = now.difference(breakStart).inMinutes;
          if (breakDurationMins > 60) {
            overstayedBreaksCount++;
            anomalies.add('$name: Extended break ($breakDurationMins mins on ${latestPunch['breakType'] ?? 'Break'})');
          }
        }
      }
    }

    // Leave count
    final onLeaveCount = leaveUserIds.length;
    // Absent count
    final absentCount = (totalHeadcount - presentCount - onLeaveCount).clamp(0, totalHeadcount);

    return DailyAttendanceDigest(
      date: date,
      totalHeadcount: totalHeadcount,
      presentCount: presentCount,
      lateCount: lateCount,
      absentCount: absentCount,
      onLeaveCount: onLeaveCount,
      unclosedShiftsCount: unclosedShiftsCount,
      overstayedBreaksCount: overstayedBreaksCount,
      totalOvertimeHours: totalOvertimeMinutes / 60.0,
      criticalAnomalies: anomalies,
    );
  }

  static DateTime _parseTimestamp(dynamic raw) => AppFormatUtils.parseTimestamp(raw);

  static String _formatTime(DateTime dt) => AppFormatUtils.formatTimeAmPm(dt);
}
