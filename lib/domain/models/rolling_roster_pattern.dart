/// Shift assignment type in a rotation pattern
enum ShiftCycleType {
  morning,
  evening,
  night,
  restDay,
}

/// A single step/day in the cyclical pattern
class ShiftPatternStep {
  final int dayIndex; // 0-indexed within cycle
  final ShiftCycleType cycleType;
  final String shiftName;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const ShiftPatternStep({
    required this.dayIndex,
    required this.cycleType,
    required this.shiftName,
    this.startHour = 9,
    this.startMinute = 0,
    this.endHour = 17,
    this.endMinute = 0,
  });

  bool get isRestDay => cycleType == ShiftCycleType.restDay;

  Map<String, dynamic> toMap() => {
    'dayIndex': dayIndex,
    'cycleType': cycleType.name,
    'shiftName': shiftName,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
  };

  factory ShiftPatternStep.fromMap(Map<String, dynamic> map) {
    return ShiftPatternStep(
      dayIndex: (map['dayIndex'] as num?)?.toInt() ?? 0,
      cycleType: ShiftCycleType.values.firstWhere(
        (e) => e.name == map['cycleType'],
        orElse: () => ShiftCycleType.morning,
      ),
      shiftName: map['shiftName'] as String? ?? 'Shift',
      startHour: (map['startHour'] as num?)?.toInt() ?? 9,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 17,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Enterprise rolling shift pattern definition (e.g. 4 on 4 off, or 2M-2E-2N-4O)
class RollingRosterPattern {
  final String patternId;
  final String enterpriseId;
  final String name; // e.g. "Continental 2-2-2-4"
  final DateTime anchorStartDate; // Reference day index 0
  final List<ShiftPatternStep> steps;

  const RollingRosterPattern({
    required this.patternId,
    required this.enterpriseId,
    required this.name,
    required this.anchorStartDate,
    required this.steps,
  });

  int get cycleLengthDays => steps.length;

  Map<String, dynamic> toMap() => {
    'patternId': patternId,
    'enterpriseId': enterpriseId,
    'name': name,
    'anchorStartDate': anchorStartDate.toIso8601String(),
    'steps': steps.map((s) => s.toMap()).toList(),
  };

  factory RollingRosterPattern.fromMap(Map<String, dynamic> map) {
    return RollingRosterPattern(
      patternId: map['patternId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      name: map['name'] as String? ?? 'Shift Pattern',
      anchorStartDate: map['anchorStartDate'] != null
          ? DateTime.tryParse(map['anchorStartDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      steps: (map['steps'] as List? ?? [])
          .map((s) => ShiftPatternStep.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
}

/// Projected shift for an employee on a target date
class ProjectedShiftAssignment {
  final DateTime date;
  final ShiftPatternStep step;
  final String employeeId;
  final int cycleDayNumber;

  const ProjectedShiftAssignment({
    required this.date,
    required this.step,
    required this.employeeId,
    required this.cycleDayNumber,
  });
}
