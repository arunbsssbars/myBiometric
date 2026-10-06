/// Represents a daily time window for access authorization.
class TimeSpanWindow {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeSpanWindow({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  bool containsTime(int hour, int minute) {
    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;
    final currentTotal = hour * 60 + minute;
    return currentTotal >= startTotal && currentTotal <= endTotal;
  }

  Map<String, dynamic> toMap() {
    return {
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
    };
  }

  factory TimeSpanWindow.fromMap(Map<String, dynamic> map) {
    return TimeSpanWindow(
      startHour: (map['startHour'] as num?)?.toInt() ?? 0,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 23,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 59,
    );
  }
}

/// Access schedule profile governing when physical doors and turnstiles unlock.
enum TerminalScheduleType {
  alwaysOpen,
  workHoursOnly,
  shiftBound,
  customWeekly,
}

/// Domain model for external terminal access control templates and door unlock rules.
class TerminalAccessSchedule {
  final String id;
  final String enterpriseId;
  final String name;
  final TerminalScheduleType type;
  final bool isDefault;
  final int graceBeforeShiftMins;
  final int graceAfterShiftMins;
  final bool allowManagerOverride;
  final Map<int, List<TimeSpanWindow>> weeklyWindows; // 1 (Mon) to 7 (Sun)

  const TerminalAccessSchedule({
    required this.id,
    required this.enterpriseId,
    required this.name,
    this.type = TerminalScheduleType.workHoursOnly,
    this.isDefault = false,
    this.graceBeforeShiftMins = 30,
    this.graceAfterShiftMins = 60,
    this.allowManagerOverride = true,
    this.weeklyWindows = const {},
  });

  /// Factory for standard office business hours (Mon-Fri 08:00 - 19:00).
  factory TerminalAccessSchedule.standardOffice(String enterpriseId) {
    const standardDay = [TimeSpanWindow(startHour: 8, startMinute: 0, endHour: 19, endMinute: 0)];
    return TerminalAccessSchedule(
      id: 'sched_standard_office',
      enterpriseId: enterpriseId,
      name: 'Standard Office Hours (08:00 - 19:00)',
      type: TerminalScheduleType.workHoursOnly,
      isDefault: true,
      weeklyWindows: {
        1: standardDay,
        2: standardDay,
        3: standardDay,
        4: standardDay,
        5: standardDay,
        6: const [], // Closed Saturday
        7: const [], // Closed Sunday
      },
    );
  }

  /// Evaluates whether access is authorized at a given DateTime.
  bool isAccessAuthorized(DateTime time, {bool isManager = false}) {
    if (isManager && allowManagerOverride) return true;
    if (type == TerminalScheduleType.alwaysOpen) return true;

    final weekday = time.weekday;
    final windows = weeklyWindows[weekday];
    if (windows == null || windows.isEmpty) return false;

    for (final window in windows) {
      if (window.containsTime(time.hour, time.minute)) {
        return true;
      }
    }
    return false;
  }

  /// Generates Hikvision ISAPI TimeSchedule JSON/XML payload block.
  Map<String, dynamic> toHikvisionIsapiSchedule() {
    final List<Map<String, dynamic>> days = [];
    for (int i = 1; i <= 7; i++) {
      final windows = weeklyWindows[i] ?? [];
      final List<Map<String, dynamic>> timeSegments = [];
      for (final w in windows) {
        timeSegments.add({
          'beginTime': '${w.startHour.toString().padLeft(2, '0')}:${w.startMinute.toString().padLeft(2, '0')}:00',
          'endTime': '${w.endHour.toString().padLeft(2, '0')}:${w.endMinute.toString().padLeft(2, '0')}:00',
        });
      }
      days.add({
        'dayOfWeek': i,
        'TimeSegment': timeSegments,
      });
    }

    return {
      'TimeSchedule': {
        'id': id,
        'name': name,
        'ScheduleDay': days,
      }
    };
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> windowsMap = {};
    weeklyWindows.forEach((day, windows) {
      windowsMap[day.toString()] = windows.map((w) => w.toMap()).toList();
    });

    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      'type': type.name,
      'isDefault': isDefault,
      'graceBeforeShiftMins': graceBeforeShiftMins,
      'graceAfterShiftMins': graceAfterShiftMins,
      'allowManagerOverride': allowManagerOverride,
      'weeklyWindows': windowsMap,
    };
  }

  factory TerminalAccessSchedule.fromMap(Map<String, dynamic> map, {required String id}) {
    final rawWindows = map['weeklyWindows'] as Map<String, dynamic>? ?? {};
    final Map<int, List<TimeSpanWindow>> parsedWindows = {};

    rawWindows.forEach((dayStr, list) {
      final dayInt = int.tryParse(dayStr) ?? 1;
      if (list is List) {
        parsedWindows[dayInt] = list
            .map((item) => TimeSpanWindow.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    });

    return TerminalAccessSchedule(
      id: id,
      enterpriseId: (map['enterpriseId'] ?? '').toString(),
      name: (map['name'] ?? 'Access Schedule').toString(),
      type: TerminalScheduleType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TerminalScheduleType.workHoursOnly,
      ),
      isDefault: map['isDefault'] as bool? ?? false,
      graceBeforeShiftMins: (map['graceBeforeShiftMins'] as num?)?.toInt() ?? 30,
      graceAfterShiftMins: (map['graceAfterShiftMins'] as num?)?.toInt() ?? 60,
      allowManagerOverride: map['allowManagerOverride'] as bool? ?? true,
      weeklyWindows: parsedWindows,
    );
  }
}
