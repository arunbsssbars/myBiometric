/// Domain model defining enterprise overtime calculation policies and tier multipliers.
class OvertimePolicy {
  final bool isEnabled;
  final int dailyStandardThresholdMinutes; // e.g. 480 mins (8.0 hours)
  final int dailyDoubleThresholdMinutes; // e.g. 720 mins (12.0 hours)
  final int weeklyThresholdMinutes; // e.g. 2400 mins (40.0 hours)
  final double standardOvertimeMultiplier; // e.g. 1.5x
  final double doubleOvertimeMultiplier; // e.g. 2.0x
  final double restDayMultiplier; // e.g. 1.5x
  final double holidayMultiplier; // e.g. 2.0x

  const OvertimePolicy({
    this.isEnabled = true,
    this.dailyStandardThresholdMinutes = 480,
    this.dailyDoubleThresholdMinutes = 720,
    this.weeklyThresholdMinutes = 2400,
    this.standardOvertimeMultiplier = 1.5,
    this.doubleOvertimeMultiplier = 2.0,
    this.restDayMultiplier = 1.5,
    this.holidayMultiplier = 2.0,
  });

  /// Standard enterprise preset (8h regular, 1.5x OT up to 12h, 2.0x double OT after 12h, 40h weekly cap)
  factory OvertimePolicy.standard() => const OvertimePolicy();

  /// Relaxed/Generous overtime preset (starts after 7.5h or 37.5h weekly)
  factory OvertimePolicy.generous() => const OvertimePolicy(
        dailyStandardThresholdMinutes: 450,
        dailyDoubleThresholdMinutes: 660,
        weeklyThresholdMinutes: 2250,
        standardOvertimeMultiplier: 1.5,
        doubleOvertimeMultiplier: 2.0,
      );

  /// Disabled overtime policy (all hours regular 1.0x)
  factory OvertimePolicy.disabled() => const OvertimePolicy(isEnabled: false);

  factory OvertimePolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OvertimePolicy();
    return OvertimePolicy(
      isEnabled: json['isEnabled'] as bool? ?? true,
      dailyStandardThresholdMinutes: (json['dailyStandardThresholdMinutes'] as num?)?.toInt() ?? 480,
      dailyDoubleThresholdMinutes: (json['dailyDoubleThresholdMinutes'] as num?)?.toInt() ?? 720,
      weeklyThresholdMinutes: (json['weeklyThresholdMinutes'] as num?)?.toInt() ?? 2400,
      standardOvertimeMultiplier: (json['standardOvertimeMultiplier'] as num?)?.toDouble() ?? 1.5,
      doubleOvertimeMultiplier: (json['doubleOvertimeMultiplier'] as num?)?.toDouble() ?? 2.0,
      restDayMultiplier: (json['restDayMultiplier'] as num?)?.toDouble() ?? 1.5,
      holidayMultiplier: (json['holidayMultiplier'] as num?)?.toDouble() ?? 2.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'dailyStandardThresholdMinutes': dailyStandardThresholdMinutes,
        'dailyDoubleThresholdMinutes': dailyDoubleThresholdMinutes,
        'weeklyThresholdMinutes': weeklyThresholdMinutes,
        'standardOvertimeMultiplier': standardOvertimeMultiplier,
        'doubleOvertimeMultiplier': doubleOvertimeMultiplier,
        'restDayMultiplier': restDayMultiplier,
        'holidayMultiplier': holidayMultiplier,
      };

  OvertimePolicy copyWith({
    bool? isEnabled,
    int? dailyStandardThresholdMinutes,
    int? dailyDoubleThresholdMinutes,
    int? weeklyThresholdMinutes,
    double? standardOvertimeMultiplier,
    double? doubleOvertimeMultiplier,
    double? restDayMultiplier,
    double? holidayMultiplier,
  }) {
    return OvertimePolicy(
      isEnabled: isEnabled ?? this.isEnabled,
      dailyStandardThresholdMinutes: dailyStandardThresholdMinutes ?? this.dailyStandardThresholdMinutes,
      dailyDoubleThresholdMinutes: dailyDoubleThresholdMinutes ?? this.dailyDoubleThresholdMinutes,
      weeklyThresholdMinutes: weeklyThresholdMinutes ?? this.weeklyThresholdMinutes,
      standardOvertimeMultiplier: standardOvertimeMultiplier ?? this.standardOvertimeMultiplier,
      doubleOvertimeMultiplier: doubleOvertimeMultiplier ?? this.doubleOvertimeMultiplier,
      restDayMultiplier: restDayMultiplier ?? this.restDayMultiplier,
      holidayMultiplier: holidayMultiplier ?? this.holidayMultiplier,
    );
  }
}
