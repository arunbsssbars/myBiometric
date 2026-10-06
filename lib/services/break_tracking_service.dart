import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported types of workplace breaks.
enum BreakCategory {
  lunch,
  rest,
  custom;

  bool get isPaid => this == BreakCategory.rest;

  String get displayName {
    switch (this) {
      case BreakCategory.lunch:
        return 'Lunch Break';
      case BreakCategory.rest:
        return 'Rest / Tea Break';
      case BreakCategory.custom:
        return 'Custom Break';
    }
  }

  int get standardMinutes {
    switch (this) {
      case BreakCategory.lunch:
        return 45;
      case BreakCategory.rest:
        return 15;
      case BreakCategory.custom:
        return 30;
    }
  }

  static BreakCategory fromString(String? name) {
    if (name == null) return BreakCategory.lunch;
    final lower = name.toLowerCase();
    if (lower.contains('lunch') || lower.contains('meal')) {
      return BreakCategory.lunch;
    }
    if (lower.contains('tea') || lower.contains('coffee') || lower.contains('rest')) {
      return BreakCategory.rest;
    }
    return BreakCategory.custom;
  }
}

/// Real-time live status for an employee today.
enum EmployeeWorkStatus {
  working,
  onBreak,
  clockedOut,
  absent,
  onLeave;

  String get displayName {
    switch (this) {
      case EmployeeWorkStatus.working:
        return 'Working';
      case EmployeeWorkStatus.onBreak:
        return 'On Break';
      case EmployeeWorkStatus.clockedOut:
        return 'Clocked Out';
      case EmployeeWorkStatus.absent:
        return 'Not In';
      case EmployeeWorkStatus.onLeave:
        return 'On Leave';
    }
  }
}

/// Detailed evaluation of an employee's attendance & breaks today.
class EmployeeDailySession {
  final String userId;
  final String employeeName;
  final String employeeId;
  final String department;
  final EmployeeWorkStatus status;
  final DateTime? punchInTime;
  final DateTime? punchOutTime;
  final DateTime? breakStartTime;
  final BreakCategory? activeBreakCategory;
  final Duration totalBreakDuration;
  final Duration unpaidBreakDuration;
  final Duration paidBreakDuration;
  final Duration grossDuration;
  final Duration netWorkDuration;
  final String? lastVerifiedVia;
  final String? leaveReason;
  final bool isOverstayedBreak;
  final int overstayMinutes;

  const EmployeeDailySession({
    required this.userId,
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.status,
    this.punchInTime,
    this.punchOutTime,
    this.breakStartTime,
    this.activeBreakCategory,
    this.totalBreakDuration = Duration.zero,
    this.unpaidBreakDuration = Duration.zero,
    this.paidBreakDuration = Duration.zero,
    this.grossDuration = Duration.zero,
    this.netWorkDuration = Duration.zero,
    this.lastVerifiedVia,
    this.leaveReason,
    this.isOverstayedBreak = false,
    this.overstayMinutes = 0,
  });

  /// Evaluates the session from today's attendance logs for an employee.
  factory EmployeeDailySession.evaluate({
    required String userId,
    required String employeeName,
    required String employeeId,
    required String department,
    required List<Map<String, dynamic>> employeeLogsToday,
    bool isOnApprovedLeave = false,
    String? leaveReason,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();

    if (isOnApprovedLeave) {
      return EmployeeDailySession(
        userId: userId,
        employeeName: employeeName,
        employeeId: employeeId,
        department: department,
        status: EmployeeWorkStatus.onLeave,
        leaveReason: leaveReason ?? 'Approved Leave',
      );
    }

    if (employeeLogsToday.isEmpty) {
      return EmployeeDailySession(
        userId: userId,
        employeeName: employeeName,
        employeeId: employeeId,
        department: department,
        status: EmployeeWorkStatus.absent,
      );
    }

    DateTime parseTs(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime(0);
      return DateTime(0);
    }

    // Sort logs chronologically (oldest to newest)
    final sortedLogs = List<Map<String, dynamic>>.from(employeeLogsToday);
    sortedLogs.sort((a, b) {
      final tA = parseTs(a['timestamp']);
      final tB = parseTs(b['timestamp']);
      return tA.compareTo(tB);
    });

    DateTime? firstIn;
    DateTime? lastOut;
    DateTime? currentBreakStart;
    BreakCategory? currentBreakCat;

    Duration totalBreak = Duration.zero;
    Duration unpaidBreak = Duration.zero;
    Duration paidBreak = Duration.zero;

    DateTime? openBreakStart;
    BreakCategory? openBreakCat;

    for (final log in sortedLogs) {
      final type = log['type'] as String?;
      final dynamic rawTs = log['timestamp'];
      final ts = rawTs is Timestamp ? rawTs.toDate() : (rawTs is DateTime ? rawTs : null);
      if (ts == null) continue;

      if (type == 'PUNCH_IN') {
        firstIn ??= ts;
        // In case previous session was marked out, subsequent punch-in continues
        lastOut = null;
      } else if (type == 'PUNCH_OUT') {
        lastOut = ts;
        // Auto-close open break if any
        if (openBreakStart != null) {
          final bDur = ts.difference(openBreakStart);
          totalBreak += bDur;
          if (openBreakCat?.isPaid == true) {
            paidBreak += bDur;
          } else {
            unpaidBreak += bDur;
          }
          openBreakStart = null;
          openBreakCat = null;
        }
      } else if (type == 'START_BREAK') {
        final cat = BreakCategory.fromString(log['breakType'] as String?);
        openBreakStart = ts;
        openBreakCat = cat;
        currentBreakStart = ts;
        currentBreakCat = cat;
      } else if (type == 'END_BREAK') {
        if (openBreakStart != null) {
          final bDur = ts.difference(openBreakStart);
          totalBreak += bDur;
          if (openBreakCat?.isPaid == true) {
            paidBreak += bDur;
          } else {
            unpaidBreak += bDur;
          }
          openBreakStart = null;
          openBreakCat = null;
        }
        currentBreakStart = null;
        currentBreakCat = null;
      }
    }

    final latestLog = sortedLogs.last;
    final latestType = latestLog['type'] as String?;
    final lastVerified = latestLog['verifiedVia'] as String?;

    EmployeeWorkStatus finalStatus;
    if (firstIn == null) {
      finalStatus = EmployeeWorkStatus.absent;
    } else if (lastOut != null) {
      finalStatus = EmployeeWorkStatus.clockedOut;
    } else if (latestType == 'START_BREAK') {
      finalStatus = EmployeeWorkStatus.onBreak;
      // Add current elapsed break to total break
      if (openBreakStart != null) {
        final liveBDur = now.difference(openBreakStart);
        totalBreak += liveBDur;
        if (openBreakCat?.isPaid == true) {
          paidBreak += liveBDur;
        } else {
          unpaidBreak += liveBDur;
        }
      }
    } else {
      finalStatus = EmployeeWorkStatus.working;
    }

    Duration gross = Duration.zero;
    if (firstIn != null) {
      final endTime = lastOut ?? now;
      gross = endTime.difference(firstIn);
      if (gross.isNegative) gross = Duration.zero;
    }

    Duration net = gross - unpaidBreak;
    if (net.isNegative) net = Duration.zero;

    bool isOverstay = false;
    int overstayMins = 0;
    if (finalStatus == EmployeeWorkStatus.onBreak && currentBreakStart != null && currentBreakCat != null) {
      final elapsed = now.difference(currentBreakStart).inMinutes;
      if (elapsed > currentBreakCat.standardMinutes) {
        isOverstay = true;
        overstayMins = elapsed - currentBreakCat.standardMinutes;
      }
    }

    return EmployeeDailySession(
      userId: userId,
      employeeName: employeeName,
      employeeId: employeeId,
      department: department,
      status: finalStatus,
      punchInTime: firstIn,
      punchOutTime: lastOut,
      breakStartTime: currentBreakStart,
      activeBreakCategory: currentBreakCat,
      totalBreakDuration: totalBreak,
      unpaidBreakDuration: unpaidBreak,
      paidBreakDuration: paidBreak,
      grossDuration: gross,
      netWorkDuration: net,
      lastVerifiedVia: lastVerified,
      isOverstayedBreak: isOverstay,
      overstayMinutes: overstayMins,
    );
  }
}
