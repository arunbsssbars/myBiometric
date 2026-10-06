import 'package:flutter/foundation.dart';

enum ComplianceSeverity {
  info,
  warning,
  violation,
}

enum ComplianceIssueType {
  insufficientRestBetweenShifts,
  excessiveConsecutiveDays,
  excessiveWeeklyHours,
  excessiveDailyHours,
  missedMandatoryBreak,
}

@immutable
class LaborCompliancePolicy {
  final double minRestHoursBetweenShifts; // e.g. 11.0 hours (statutory minimum rest between shifts)
  final int maxConsecutiveWorkdays; // e.g. 6 days (mandatory rest day)
  final double maxWeeklyWorkHours; // e.g. 48.0 hours
  final double maxDailyWorkHours; // e.g. 12.0 hours
  final double mandatoryMealBreakAfterHours; // e.g. 5.0 hours
  final int minMealBreakMinutes; // e.g. 30 minutes
  final bool isEnforced;
  final DateTime? updatedAt;

  const LaborCompliancePolicy({
    this.minRestHoursBetweenShifts = 11.0,
    this.maxConsecutiveWorkdays = 6,
    this.maxWeeklyWorkHours = 48.0,
    this.maxDailyWorkHours = 12.0,
    this.mandatoryMealBreakAfterHours = 5.0,
    this.minMealBreakMinutes = 30,
    this.isEnforced = true,
    this.updatedAt,
  });

  factory LaborCompliancePolicy.defaultPolicy() {
    return const LaborCompliancePolicy(
      minRestHoursBetweenShifts: 11.0,
      maxConsecutiveWorkdays: 6,
      maxWeeklyWorkHours: 48.0,
      maxDailyWorkHours: 12.0,
      mandatoryMealBreakAfterHours: 5.0,
      minMealBreakMinutes: 30,
      isEnforced: true,
    );
  }

  factory LaborCompliancePolicy.fromMap(Map<String, dynamic> map) {
    return LaborCompliancePolicy(
      minRestHoursBetweenShifts: (map['minRestHoursBetweenShifts'] as num?)?.toDouble() ?? 11.0,
      maxConsecutiveWorkdays: (map['maxConsecutiveWorkdays'] as num?)?.toInt() ?? 6,
      maxWeeklyWorkHours: (map['maxWeeklyWorkHours'] as num?)?.toDouble() ?? 48.0,
      maxDailyWorkHours: (map['maxDailyWorkHours'] as num?)?.toDouble() ?? 12.0,
      mandatoryMealBreakAfterHours: (map['mandatoryMealBreakAfterHours'] as num?)?.toDouble() ?? 5.0,
      minMealBreakMinutes: (map['minMealBreakMinutes'] as num?)?.toInt() ?? 30,
      isEnforced: map['isEnforced'] as bool? ?? true,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minRestHoursBetweenShifts': minRestHoursBetweenShifts,
      'maxConsecutiveWorkdays': maxConsecutiveWorkdays,
      'maxWeeklyWorkHours': maxWeeklyWorkHours,
      'maxDailyWorkHours': maxDailyWorkHours,
      'mandatoryMealBreakAfterHours': mandatoryMealBreakAfterHours,
      'minMealBreakMinutes': minMealBreakMinutes,
      'isEnforced': isEnforced,
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  LaborCompliancePolicy copyWith({
    double? minRestHoursBetweenShifts,
    int? maxConsecutiveWorkdays,
    double? maxWeeklyWorkHours,
    double? maxDailyWorkHours,
    double? mandatoryMealBreakAfterHours,
    int? minMealBreakMinutes,
    bool? isEnforced,
    DateTime? updatedAt,
  }) {
    return LaborCompliancePolicy(
      minRestHoursBetweenShifts: minRestHoursBetweenShifts ?? this.minRestHoursBetweenShifts,
      maxConsecutiveWorkdays: maxConsecutiveWorkdays ?? this.maxConsecutiveWorkdays,
      maxWeeklyWorkHours: maxWeeklyWorkHours ?? this.maxWeeklyWorkHours,
      maxDailyWorkHours: maxDailyWorkHours ?? this.maxDailyWorkHours,
      mandatoryMealBreakAfterHours: mandatoryMealBreakAfterHours ?? this.mandatoryMealBreakAfterHours,
      minMealBreakMinutes: minMealBreakMinutes ?? this.minMealBreakMinutes,
      isEnforced: isEnforced ?? this.isEnforced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ComplianceIncident {
  final String id;
  final String employeeId;
  final String employeeName;
  final ComplianceIssueType issueType;
  final ComplianceSeverity severity;
  final String description;
  final DateTime timestamp;
  final double metricValue;
  final double thresholdValue;
  final bool resolved;

  const ComplianceIncident({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.issueType,
    required this.severity,
    required this.description,
    required this.timestamp,
    required this.metricValue,
    required this.thresholdValue,
    this.resolved = false,
  });

  String get issueTitle {
    switch (issueType) {
      case ComplianceIssueType.insufficientRestBetweenShifts:
        return 'Insufficient Rest Between Shifts';
      case ComplianceIssueType.excessiveConsecutiveDays:
        return 'Consecutive Workdays Limit Exceeded';
      case ComplianceIssueType.excessiveWeeklyHours:
        return 'Weekly Maximum Hours Breach';
      case ComplianceIssueType.excessiveDailyHours:
        return 'Daily Maximum Hours Exceeded';
      case ComplianceIssueType.missedMandatoryBreak:
        return 'Missed Mandatory Rest/Meal Break';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'issueType': issueType.name,
      'severity': severity.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metricValue': metricValue,
      'thresholdValue': thresholdValue,
      'resolved': resolved,
    };
  }

  factory ComplianceIncident.fromMap(Map<String, dynamic> map) {
    return ComplianceIncident(
      id: map['id']?.toString() ?? '',
      employeeId: map['employeeId']?.toString() ?? '',
      employeeName: map['employeeName']?.toString() ?? 'Employee',
      issueType: ComplianceIssueType.values.firstWhere(
        (e) => e.name == map['issueType'],
        orElse: () => ComplianceIssueType.insufficientRestBetweenShifts,
      ),
      severity: ComplianceSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => ComplianceSeverity.warning,
      ),
      description: map['description']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      metricValue: (map['metricValue'] as num?)?.toDouble() ?? 0.0,
      thresholdValue: (map['thresholdValue'] as num?)?.toDouble() ?? 0.0,
      resolved: map['resolved'] as bool? ?? false,
    );
  }
}

class ComplianceAuditReport {
  final DateTime generatedAt;
  final int totalInspectedEmployees;
  final int totalInspectedLogs;
  final int totalViolations;
  final int totalWarnings;
  final List<ComplianceIncident> incidents;
  final double complianceScorePercent;

  const ComplianceAuditReport({
    required this.generatedAt,
    required this.totalInspectedEmployees,
    required this.totalInspectedLogs,
    required this.totalViolations,
    required this.totalWarnings,
    required this.incidents,
    required this.complianceScorePercent,
  });

  bool get hasCriticalViolations => totalViolations > 0;
  int get cleanRecordsCount => (totalInspectedLogs - totalViolations - totalWarnings).clamp(0, totalInspectedLogs);
}
