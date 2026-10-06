/// Domain model encapsulating the automated end-of-day attendance digest and anomaly summary
class DailyAttendanceDigest {
  final DateTime date;
  final int totalHeadcount;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int onLeaveCount;
  final int unclosedShiftsCount; // Clocked in but never clocked out
  final int overstayedBreaksCount;
  final double totalOvertimeHours;
  final List<String> criticalAnomalies;

  const DailyAttendanceDigest({
    required this.date,
    required this.totalHeadcount,
    required this.presentCount,
    this.lateCount = 0,
    this.absentCount = 0,
    this.onLeaveCount = 0,
    this.unclosedShiftsCount = 0,
    this.overstayedBreaksCount = 0,
    this.totalOvertimeHours = 0.0,
    this.criticalAnomalies = const [],
  });

  /// On-time arrival rate percentage among present employees (0.0 to 100.0)
  double get onTimeRatePercent {
    if (presentCount <= 0) return 100.0;
    final onTimeCount = presentCount - lateCount;
    return ((onTimeCount > 0 ? onTimeCount : 0) / presentCount) * 100.0;
  }

  /// Attendance compliance rate percentage across total headcount
  double get attendanceRatePercent {
    if (totalHeadcount <= 0) return 0.0;
    return (presentCount / totalHeadcount) * 100.0;
  }

  bool get hasCriticalAnomalies =>
      unclosedShiftsCount > 0 || overstayedBreaksCount > 0 || criticalAnomalies.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalHeadcount': totalHeadcount,
        'presentCount': presentCount,
        'lateCount': lateCount,
        'absentCount': absentCount,
        'onLeaveCount': onLeaveCount,
        'unclosedShiftsCount': unclosedShiftsCount,
        'overstayedBreaksCount': overstayedBreaksCount,
        'totalOvertimeHours': totalOvertimeHours,
        'criticalAnomalies': criticalAnomalies,
      };

  factory DailyAttendanceDigest.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return DailyAttendanceDigest(
        date: DateTime.now(),
        totalHeadcount: 0,
        presentCount: 0,
      );
    }

    return DailyAttendanceDigest(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      totalHeadcount: (json['totalHeadcount'] as num?)?.toInt() ?? 0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      onLeaveCount: (json['onLeaveCount'] as num?)?.toInt() ?? 0,
      unclosedShiftsCount: (json['unclosedShiftsCount'] as num?)?.toInt() ?? 0,
      overstayedBreaksCount: (json['overstayedBreaksCount'] as num?)?.toInt() ?? 0,
      totalOvertimeHours: (json['totalOvertimeHours'] as num?)?.toDouble() ?? 0.0,
      criticalAnomalies: (json['criticalAnomalies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
