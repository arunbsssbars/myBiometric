/// Domain model defining automated shift closure and break deduction rules (Jibble-compliant)
class ShiftAutomationPolicy {
  final bool autoClockOutEnabled;
  final bool autoClockOutAtShiftEnd; // Clock out automatically at shift's scheduled end time
  final int autoClockOutMaxShiftHours; // Max shift duration cap before auto-clockout (e.g. 12 hours)
  final bool autoDeductLunchEnabled; // Auto-deduct unpaid meal break if employee didn't log one
  final int autoDeductThresholdMinutes; // Minimum work duration before deduction applies (e.g. 360m / 6h)
  final int autoDeductLunchMinutes; // Duration to deduct (e.g. 30m or 60m)

  const ShiftAutomationPolicy({
    this.autoClockOutEnabled = true,
    this.autoClockOutAtShiftEnd = false,
    this.autoClockOutMaxShiftHours = 12,
    this.autoDeductLunchEnabled = true,
    this.autoDeductThresholdMinutes = 360, // 6 hours
    this.autoDeductLunchMinutes = 60, // 1 hour
  });

  /// Standard enterprise default policy
  factory ShiftAutomationPolicy.standard() => const ShiftAutomationPolicy();

  /// Strict shift boundary policy (auto clock-out exactly at shift end)
  factory ShiftAutomationPolicy.strict() => const ShiftAutomationPolicy(
        autoClockOutEnabled: true,
        autoClockOutAtShiftEnd: true,
        autoClockOutMaxShiftHours: 10,
        autoDeductLunchEnabled: true,
        autoDeductThresholdMinutes: 300,
        autoDeductLunchMinutes: 60,
      );

  /// Disabled automation
  factory ShiftAutomationPolicy.disabled() => const ShiftAutomationPolicy(
        autoClockOutEnabled: false,
        autoClockOutAtShiftEnd: false,
        autoDeductLunchEnabled: false,
      );

  factory ShiftAutomationPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShiftAutomationPolicy();
    return ShiftAutomationPolicy(
      autoClockOutEnabled: json['autoClockOutEnabled'] as bool? ?? true,
      autoClockOutAtShiftEnd: json['autoClockOutAtShiftEnd'] as bool? ?? false,
      autoClockOutMaxShiftHours: (json['autoClockOutMaxShiftHours'] as num?)?.toInt() ?? 12,
      autoDeductLunchEnabled: json['autoDeductLunchEnabled'] as bool? ?? true,
      autoDeductThresholdMinutes: (json['autoDeductThresholdMinutes'] as num?)?.toInt() ?? 360,
      autoDeductLunchMinutes: (json['autoDeductLunchMinutes'] as num?)?.toInt() ?? 60,
    );
  }

  Map<String, dynamic> toJson() => {
        'autoClockOutEnabled': autoClockOutEnabled,
        'autoClockOutAtShiftEnd': autoClockOutAtShiftEnd,
        'autoClockOutMaxShiftHours': autoClockOutMaxShiftHours,
        'autoDeductLunchEnabled': autoDeductLunchEnabled,
        'autoDeductThresholdMinutes': autoDeductThresholdMinutes,
        'autoDeductLunchMinutes': autoDeductLunchMinutes,
      };

  ShiftAutomationPolicy copyWith({
    bool? autoClockOutEnabled,
    bool? autoClockOutAtShiftEnd,
    int? autoClockOutMaxShiftHours,
    bool? autoDeductLunchEnabled,
    int? autoDeductThresholdMinutes,
    int? autoDeductLunchMinutes,
  }) {
    return ShiftAutomationPolicy(
      autoClockOutEnabled: autoClockOutEnabled ?? this.autoClockOutEnabled,
      autoClockOutAtShiftEnd: autoClockOutAtShiftEnd ?? this.autoClockOutAtShiftEnd,
      autoClockOutMaxShiftHours: autoClockOutMaxShiftHours ?? this.autoClockOutMaxShiftHours,
      autoDeductLunchEnabled: autoDeductLunchEnabled ?? this.autoDeductLunchEnabled,
      autoDeductThresholdMinutes: autoDeductThresholdMinutes ?? this.autoDeductThresholdMinutes,
      autoDeductLunchMinutes: autoDeductLunchMinutes ?? this.autoDeductLunchMinutes,
    );
  }
}
