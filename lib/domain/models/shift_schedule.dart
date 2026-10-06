/// Domain model defining enterprise shift hours, grace periods, and work day thresholds.
class ShiftSchedule {
  final String shiftName;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int gracePeriodMinutes;
  final int halfDayMinutes;
  final int fullDayMinutes;

  const ShiftSchedule({
    this.shiftName = 'General Shift',
    this.startHour = 9,
    this.startMinute = 0,
    this.endHour = 18,
    this.endMinute = 0,
    this.gracePeriodMinutes = 15,
    this.halfDayMinutes = 240, // 4 hours
    this.fullDayMinutes = 480, // 8 hours
  });

  /// Formatted scheduled start (e.g., "09:00 AM")
  String get startTimeFormatted => _formatTime(startHour, startMinute);

  /// Formatted scheduled end (e.g., "06:00 PM")
  String get endTimeFormatted => _formatTime(endHour, endMinute);

  /// Formatted start with grace period (e.g., "09:15 AM")
  String get graceDeadlineFormatted {
    final totalMins = startHour * 60 + startMinute + gracePeriodMinutes;
    final h = (totalMins ~/ 60) % 24;
    final m = totalMins % 60;
    return _formatTime(h, m);
  }

  /// Shift nominal duration in hours (e.g., "9 hrs 0 mins")
  String get nominalDurationFormatted {
    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;
    final diff = endTotal >= startTotal ? endTotal - startTotal : (24 * 60 - startTotal) + endTotal;
    final h = diff ~/ 60;
    final m = diff % 60;
    return m > 0 ? '$h hrs $m mins' : '$h hrs';
  }

  Map<String, dynamic> toJson() => {
        'shiftName': shiftName,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'gracePeriodMinutes': gracePeriodMinutes,
        'halfDayMinutes': halfDayMinutes,
        'fullDayMinutes': fullDayMinutes,
      };

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) {
    return ShiftSchedule(
      shiftName: json['shiftName'] as String? ?? 'General Shift',
      startHour: json['startHour'] as int? ?? 9,
      startMinute: json['startMinute'] as int? ?? 0,
      endHour: json['endHour'] as int? ?? 18,
      endMinute: json['endMinute'] as int? ?? 0,
      gracePeriodMinutes: json['gracePeriodMinutes'] as int? ?? 15,
      halfDayMinutes: json['halfDayMinutes'] as int? ?? 240,
    );
  }

  factory ShiftSchedule.fromPreset(String? preset) {
    switch (preset?.toLowerCase()) {
      case 'morning':
      case 'morning shift':
        return const ShiftSchedule(
          shiftName: 'Morning Shift',
          startHour: 6,
          startMinute: 0,
          endHour: 14,
          endMinute: 0,
        );
      case 'evening':
      case 'evening shift':
        return const ShiftSchedule(
          shiftName: 'Evening Shift',
          startHour: 14,
          startMinute: 0,
          endHour: 22,
          endMinute: 0,
        );
      case 'night':
      case 'night shift':
        return const ShiftSchedule(
          shiftName: 'Night Shift',
          startHour: 22,
          startMinute: 0,
          endHour: 6,
          endMinute: 0,
        );
      case 'general':
      case 'general shift':
      default:
        return const ShiftSchedule();
    }
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
