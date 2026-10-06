import '../domain/models/shift_schedule.dart';

/// Structured outcome of evaluating a punch event against the enterprise shift rules.
class ShiftEvaluationResult {
  /// 'ON_TIME', 'LATE_ARRIVAL', 'EARLY_ARRIVAL', 'EARLY_DEPARTURE', or 'OVERTIME'
  final String punchStatus;

  /// Number of minutes late beyond scheduled start (0 if on time)
  final int lateMinutes;

  /// Number of minutes arrived before scheduled start or departed before scheduled end
  final int earlyMinutes;

  /// Number of minutes worked past scheduled shift end (0 if no overtime)
  final int overtimeMinutes;

  /// 'FULL_DAY', 'HALF_DAY', or 'SHORT_HOURS' (calculated on PUNCH_OUT with duration)
  final String? workStatus;

  /// User-friendly status message for notifications, toast cards, and audio announcements
  final String statusMessage;

  const ShiftEvaluationResult({
    required this.punchStatus,
    this.lateMinutes = 0,
    this.earlyMinutes = 0,
    this.overtimeMinutes = 0,
    this.workStatus,
    required this.statusMessage,
  });

  Map<String, dynamic> toJson() => {
        'punchStatus': punchStatus,
        'lateMinutes': lateMinutes,
        'earlyMinutes': earlyMinutes,
        'overtimeMinutes': overtimeMinutes,
        if (workStatus != null) 'workStatus': workStatus,
        'statusMessage': statusMessage,
      };

  factory ShiftEvaluationResult.fromJson(Map<String, dynamic> json) {
    return ShiftEvaluationResult(
      punchStatus: json['punchStatus'] as String? ?? 'ON_TIME',
      lateMinutes: json['lateMinutes'] as int? ?? 0,
      earlyMinutes: json['earlyMinutes'] as int? ?? 0,
      overtimeMinutes: json['overtimeMinutes'] as int? ?? 0,
      workStatus: json['workStatus'] as String?,
      statusMessage: json['statusMessage'] as String? ?? 'On Time',
    );
  }
}

/// Service evaluating punch events in real time against enterprise shift timings.
class ShiftEvaluationService {
  /// Evaluates an attendance punch against the assigned shift schedule.
  static ShiftEvaluationResult evaluatePunch({
    required DateTime punchTime,
    required String punchType, // 'PUNCH_IN' or 'PUNCH_OUT'
    ShiftSchedule schedule = const ShiftSchedule(),
    int? shiftDurationMinutes,
  }) {
    if (punchType == 'PUNCH_IN') {
      return _evaluatePunchIn(punchTime, schedule);
    } else {
      return _evaluatePunchOut(punchTime, schedule, shiftDurationMinutes);
    }
  }

  static ShiftEvaluationResult _evaluatePunchIn(
    DateTime punchTime,
    ShiftSchedule schedule,
  ) {
    final scheduledStart = DateTime(
      punchTime.year,
      punchTime.month,
      punchTime.day,
      schedule.startHour,
      schedule.startMinute,
    );

    final graceDeadline = scheduledStart.add(
      Duration(minutes: schedule.gracePeriodMinutes),
    );

    if (punchTime.isAfter(graceDeadline)) {
      final lateDiff = punchTime.difference(scheduledStart).inMinutes;
      final lateMins = lateDiff > 0 ? lateDiff : 1;
      final hours = lateMins ~/ 60;
      final mins = lateMins % 60;
      final lateStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

      return ShiftEvaluationResult(
        punchStatus: 'LATE_ARRIVAL',
        lateMinutes: lateMins,
        statusMessage: 'Late by $lateStr',
      );
    } else if (punchTime.isBefore(scheduledStart.subtract(const Duration(minutes: 60)))) {
      final earlyMins = scheduledStart.difference(punchTime).inMinutes;
      final hours = earlyMins ~/ 60;
      final mins = earlyMins % 60;
      final earlyStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

      return ShiftEvaluationResult(
        punchStatus: 'EARLY_ARRIVAL',
        earlyMinutes: earlyMins,
        statusMessage: 'Early by $earlyStr',
      );
    } else {
      return const ShiftEvaluationResult(
        punchStatus: 'ON_TIME',
        lateMinutes: 0,
        statusMessage: 'On Time',
      );
    }
  }

  static ShiftEvaluationResult _evaluatePunchOut(
    DateTime punchTime,
    ShiftSchedule schedule,
    int? shiftDurationMinutes,
  ) {
    final scheduledEnd = DateTime(
      punchTime.year,
      punchTime.month,
      punchTime.day,
      schedule.endHour,
      schedule.endMinute,
    );

    String? workStatus;
    if (shiftDurationMinutes != null) {
      if (shiftDurationMinutes >= schedule.fullDayMinutes) {
        workStatus = 'FULL_DAY';
      } else if (shiftDurationMinutes >= schedule.halfDayMinutes) {
        workStatus = 'HALF_DAY';
      } else {
        workStatus = 'SHORT_HOURS';
      }
    }

    if (punchTime.isBefore(scheduledEnd)) {
      final earlyMins = scheduledEnd.difference(punchTime).inMinutes;
      if (earlyMins > 10) {
        final hours = earlyMins ~/ 60;
        final mins = earlyMins % 60;
        final earlyStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

        return ShiftEvaluationResult(
          punchStatus: 'EARLY_DEPARTURE',
          earlyMinutes: earlyMins,
          workStatus: workStatus,
          statusMessage: 'Left $earlyStr early',
        );
      } else {
        return ShiftEvaluationResult(
          punchStatus: 'ON_TIME',
          workStatus: workStatus,
          statusMessage: 'On Time',
        );
      }
    } else {
      final otMins = punchTime.difference(scheduledEnd).inMinutes;
      if (otMins >= 15) {
        final hours = otMins ~/ 60;
        final mins = otMins % 60;
        final otStr = hours > 0 ? '+${hours}h ${mins}m OT' : '+${otMins}m OT';

        return ShiftEvaluationResult(
          punchStatus: 'OVERTIME',
          overtimeMinutes: otMins,
          workStatus: workStatus,
          statusMessage: otStr,
        );
      } else {
        return ShiftEvaluationResult(
          punchStatus: 'ON_TIME',
          workStatus: workStatus,
          statusMessage: 'On Time',
        );
      }
    }
  }
}
