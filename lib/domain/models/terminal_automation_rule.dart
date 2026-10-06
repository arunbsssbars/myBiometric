import 'dart:math';
import 'external_biometric_device.dart';

/// Configuration rule for automated scheduled biometric punch injection
/// matching physical hardware terminal behavior with natural jitter and high fidelity.
class TerminalAutomationRule {
  final String id;
  final String enterpriseId;
  final String employeeId;
  final String employeeName;
  final String preferredTerminalId;
  final DeviceAuthMode preferredAuthMode;
  final String shiftStartTime; // '09:00'
  final String shiftEndTime; // '18:00'
  final List<int> activeWeekdays; // 1 (Mon) - 7 (Sun)
  final int jitterMinutes; // e.g. ±1-4 mins variance for realistic parity
  final bool autoPunchIn;
  final bool autoPunchOut;
  final bool geofenceProximityRequired;
  final bool isActive;
  final DateTime? lastTriggeredAt;
  final String? lastTriggeredType;
  final DateTime createdAt;

  const TerminalAutomationRule({
    required this.id,
    required this.enterpriseId,
    required this.employeeId,
    required this.employeeName,
    required this.preferredTerminalId,
    this.preferredAuthMode = DeviceAuthMode.face,
    this.shiftStartTime = '09:00',
    this.shiftEndTime = '18:00',
    this.activeWeekdays = const [1, 2, 3, 4, 5],
    this.jitterMinutes = 3,
    this.autoPunchIn = true,
    this.autoPunchOut = true,
    this.geofenceProximityRequired = false,
    this.isActive = true,
    this.lastTriggeredAt,
    this.lastTriggeredType,
    required this.createdAt,
  });

  /// Computes a realistic timestamp with deterministic or pseudo-random jitter around the schedule time.
  DateTime computeRealisticPunchTime(DateTime baseDate, String scheduledTimeStr, {int seed = 0}) {
    final parts = scheduledTimeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final target = DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);

    if (jitterMinutes <= 0) return target;

    // Use seed for reproducibility or pseudo-random within [-jitterMinutes, +jitterMinutes]
    final rand = Random(seed != 0 ? seed : target.millisecondsSinceEpoch);
    final deltaSeconds = (rand.nextInt(jitterMinutes * 2 * 60)) - (jitterMinutes * 60);

    return target.add(Duration(seconds: deltaSeconds));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'preferredTerminalId': preferredTerminalId,
      'preferredAuthMode': preferredAuthMode.name,
      'shiftStartTime': shiftStartTime,
      'shiftEndTime': shiftEndTime,
      'activeWeekdays': activeWeekdays,
      'jitterMinutes': jitterMinutes,
      'autoPunchIn': autoPunchIn,
      'autoPunchOut': autoPunchOut,
      'geofenceProximityRequired': geofenceProximityRequired,
      'isActive': isActive,
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
      'lastTriggeredType': lastTriggeredType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TerminalAutomationRule.fromJson(Map<String, dynamic> json) {
    DeviceAuthMode parseAuthMode(String? name) {
      return DeviceAuthMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => DeviceAuthMode.face,
      );
    }

    return TerminalAutomationRule(
      id: json['id'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      preferredTerminalId: json['preferredTerminalId'] as String? ?? '',
      preferredAuthMode: parseAuthMode(json['preferredAuthMode'] as String?),
      shiftStartTime: json['shiftStartTime'] as String? ?? '09:00',
      shiftEndTime: json['shiftEndTime'] as String? ?? '18:00',
      activeWeekdays: (json['activeWeekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5],
      jitterMinutes: (json['jitterMinutes'] as num?)?.toInt() ?? 3,
      autoPunchIn: json['autoPunchIn'] as bool? ?? true,
      autoPunchOut: json['autoPunchOut'] as bool? ?? true,
      geofenceProximityRequired: json['geofenceProximityRequired'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      lastTriggeredAt: json['lastTriggeredAt'] != null
          ? DateTime.tryParse(json['lastTriggeredAt'] as String)
          : null,
      lastTriggeredType: json['lastTriggeredType'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  TerminalAutomationRule copyWith({
    String? id,
    String? enterpriseId,
    String? employeeId,
    String? employeeName,
    String? preferredTerminalId,
    DeviceAuthMode? preferredAuthMode,
    String? shiftStartTime,
    String? shiftEndTime,
    List<int>? activeWeekdays,
    int? jitterMinutes,
    bool? autoPunchIn,
    bool? autoPunchOut,
    bool? geofenceProximityRequired,
    bool? isActive,
    DateTime? lastTriggeredAt,
    String? lastTriggeredType,
    DateTime? createdAt,
  }) {
    return TerminalAutomationRule(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      preferredTerminalId: preferredTerminalId ?? this.preferredTerminalId,
      preferredAuthMode: preferredAuthMode ?? this.preferredAuthMode,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      jitterMinutes: jitterMinutes ?? this.jitterMinutes,
      autoPunchIn: autoPunchIn ?? this.autoPunchIn,
      autoPunchOut: autoPunchOut ?? this.autoPunchOut,
      geofenceProximityRequired: geofenceProximityRequired ?? this.geofenceProximityRequired,
      isActive: isActive ?? this.isActive,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      lastTriggeredType: lastTriggeredType ?? this.lastTriggeredType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
