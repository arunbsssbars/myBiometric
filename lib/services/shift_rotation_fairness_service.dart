import 'dart:math' as math;

class EmployeeShiftHistory {
  final String userId;
  final String employeeName;
  final int totalShifts;
  final int nightShifts;
  final int weekendShifts;
  final int holidayShifts;
  final int maxConsecutiveDays;

  const EmployeeShiftHistory({
    required this.userId,
    required this.employeeName,
    required this.totalShifts,
    required this.nightShifts,
    required this.weekendShifts,
    required this.holidayShifts,
    required this.maxConsecutiveDays,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'employeeName': employeeName,
    'totalShifts': totalShifts,
    'nightShifts': nightShifts,
    'weekendShifts': weekendShifts,
    'holidayShifts': holidayShifts,
    'maxConsecutiveDays': maxConsecutiveDays,
  };

  factory EmployeeShiftHistory.fromJson(Map<String, dynamic> json) {
    return EmployeeShiftHistory(
      userId: json['userId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? 'Employee',
      totalShifts: (json['totalShifts'] as num?)?.toInt() ?? 0,
      nightShifts: (json['nightShifts'] as num?)?.toInt() ?? 0,
      weekendShifts: (json['weekendShifts'] as num?)?.toInt() ?? 0,
      holidayShifts: (json['holidayShifts'] as num?)?.toInt() ?? 0,
      maxConsecutiveDays: (json['maxConsecutiveDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShiftEquityScore {
  final String userId;
  final String employeeName;
  final double fatigueRiskScore; // 0.0 - 100.0 (Higher = more fatigued)
  final double weekendLoadPercentage;
  final double nightLoadPercentage;
  final bool hasFatigueWarning;

  const ShiftEquityScore({
    required this.userId,
    required this.employeeName,
    required this.fatigueRiskScore,
    required this.weekendLoadPercentage,
    required this.nightLoadPercentage,
    required this.hasFatigueWarning,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'employeeName': employeeName,
    'fatigueRiskScore': fatigueRiskScore,
    'weekendLoadPercentage': weekendLoadPercentage,
    'nightLoadPercentage': nightLoadPercentage,
    'hasFatigueWarning': hasFatigueWarning,
  };
}

class TeamFairnessReport {
  final String department;
  final double teamFairnessIndex; // 0.0 - 100.0 (100 = completely balanced)
  final int totalTeamMembers;
  final int fatiguedMemberCount;
  final List<ShiftEquityScore> individualScores;

  const TeamFairnessReport({
    required this.department,
    required this.teamFairnessIndex,
    required this.totalTeamMembers,
    required this.fatiguedMemberCount,
    required this.individualScores,
  });
}

class ShiftRotationFairnessService {
  static final ShiftRotationFairnessService _instance = ShiftRotationFairnessService._internal();
  factory ShiftRotationFairnessService() => _instance;
  ShiftRotationFairnessService._internal();

  ShiftEquityScore evaluateEmployee(EmployeeShiftHistory history) {
    if (history.totalShifts == 0) {
      return ShiftEquityScore(
        userId: history.userId,
        employeeName: history.employeeName,
        fatigueRiskScore: 0.0,
        weekendLoadPercentage: 0.0,
        nightLoadPercentage: 0.0,
        hasFatigueWarning: false,
      );
    }

    final nightRatio = history.nightShifts / history.totalShifts;
    final weekendRatio = history.weekendShifts / history.totalShifts;

    // Fatigue risk based on consecutive days, night shifts, and holiday load
    double risk = (nightRatio * 40.0) +
        (weekendRatio * 25.0) +
        (history.maxConsecutiveDays > 6 ? 30.0 : (history.maxConsecutiveDays * 3.5)) +
        (history.holidayShifts * 5.0);

    risk = risk.clamp(0.0, 100.0);

    return ShiftEquityScore(
      userId: history.userId,
      employeeName: history.employeeName,
      fatigueRiskScore: risk,
      weekendLoadPercentage: (weekendRatio * 100.0),
      nightLoadPercentage: (nightRatio * 100.0),
      hasFatigueWarning: risk > 65.0 || history.maxConsecutiveDays >= 7,
    );
  }

  TeamFairnessReport evaluateDepartment({
    required String department,
    required List<EmployeeShiftHistory> members,
  }) {
    if (members.isEmpty) {
      return TeamFairnessReport(
        department: department,
        teamFairnessIndex: 100.0,
        totalTeamMembers: 0,
        fatiguedMemberCount: 0,
        individualScores: const [],
      );
    }

    final scores = members.map(evaluateEmployee).toList();
    final fatiguedCount = scores.where((s) => s.hasFatigueWarning).length;

    // Calculate variance in night shift allocation
    final nightCounts = members.map((m) => m.nightShifts.toDouble()).toList();
    final meanNights = nightCounts.reduce((a, b) => a + b) / nightCounts.length;

    double variance = 0.0;
    for (final count in nightCounts) {
      variance += math.pow(count - meanNights, 2);
    }
    final stdDev = math.sqrt(variance / nightCounts.length);

    // Fairness index scales inversely with standard deviation
    final fairness = (100.0 - (stdDev * 12.0)).clamp(0.0, 100.0);

    return TeamFairnessReport(
      department: department,
      teamFairnessIndex: fairness,
      totalTeamMembers: members.length,
      fatiguedMemberCount: fatiguedCount,
      individualScores: scores,
    );
  }
}
