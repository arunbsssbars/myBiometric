import '../domain/models/rolling_roster_pattern.dart';

/// Service calculating and projecting cyclical rolling shift schedules
class RollingRosterService {
  /// Projects shift assignment for an employee on a single target date
  static ProjectedShiftAssignment projectShiftForDate({
    required RollingRosterPattern pattern,
    required String employeeId,
    required DateTime targetDate,
    int teamPhaseOffsetDays = 0, // Offset for rotating teams (e.g. Team A: 0, Team B: 2)
  }) {
    if (pattern.steps.isEmpty) {
      return ProjectedShiftAssignment(
        date: targetDate,
        step: const ShiftPatternStep(
          dayIndex: 0,
          cycleType: ShiftCycleType.restDay,
          shiftName: 'Default Rest Day',
        ),
        employeeId: employeeId,
        cycleDayNumber: 1,
      );
    }

    final anchor = DateTime(
      pattern.anchorStartDate.year,
      pattern.anchorStartDate.month,
      pattern.anchorStartDate.day,
    );
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);

    final diffDays = target.difference(anchor).inDays;
    final totalOffset = diffDays + teamPhaseOffsetDays;
    final cycleLen = pattern.cycleLengthDays;

    final normalizedStepIndex = ((totalOffset % cycleLen) + cycleLen) % cycleLen;
    final step = pattern.steps[normalizedStepIndex];

    return ProjectedShiftAssignment(
      date: targetDate,
      step: step,
      employeeId: employeeId,
      cycleDayNumber: normalizedStepIndex + 1,
    );
  }

  /// Projects schedule assignments across a date range
  static List<ProjectedShiftAssignment> projectScheduleRange({
    required RollingRosterPattern pattern,
    required String employeeId,
    required DateTime startDate,
    required int numberOfDays,
    int teamPhaseOffsetDays = 0,
  }) {
    final list = <ProjectedShiftAssignment>[];
    for (int i = 0; i < numberOfDays; i++) {
      final date = startDate.add(Duration(days: i));
      list.add(
        projectShiftForDate(
          pattern: pattern,
          employeeId: employeeId,
          targetDate: date,
          teamPhaseOffsetDays: teamPhaseOffsetDays,
        ),
      );
    }
    return list;
  }
}
