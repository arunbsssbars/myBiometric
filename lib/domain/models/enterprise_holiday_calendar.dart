/// Classification of enterprise calendar holiday
enum HolidayType {
  mandatoryPublic,
  regionalStatutory,
  floatingOptional,
  companyDeclared,
}

/// A statutory holiday or company-wide declared closure
class EnterpriseHoliday {
  final String holidayId;
  final String enterpriseId;
  final String title;
  final DateTime date;
  final HolidayType type;
  final double overtimeMultiplier; // e.g. 2.0x if employee works on holiday
  final List<String> applicableBranchIds; // Empty means all branches
  final String? description;

  const EnterpriseHoliday({
    required this.holidayId,
    required this.enterpriseId,
    required this.title,
    required this.date,
    this.type = HolidayType.mandatoryPublic,
    this.overtimeMultiplier = 2.0,
    this.applicableBranchIds = const [],
    this.description,
  });

  /// Evaluates whether the holiday falls on the same calendar date
  bool isSameDay(DateTime target) {
    return date.year == target.year &&
        date.month == target.month &&
        date.day == target.day;
  }

  Map<String, dynamic> toMap() => {
    'holidayId': holidayId,
    'enterpriseId': enterpriseId,
    'title': title,
    'date': date.toIso8601String(),
    'type': type.name,
    'overtimeMultiplier': overtimeMultiplier,
    'applicableBranchIds': applicableBranchIds,
    'description': description,
  };

  factory EnterpriseHoliday.fromMap(Map<String, dynamic> map) {
    return EnterpriseHoliday(
      holidayId: map['holidayId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      title: map['title'] as String? ?? 'Holiday',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      type: HolidayType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => HolidayType.mandatoryPublic,
      ),
      overtimeMultiplier: (map['overtimeMultiplier'] as num?)?.toDouble() ?? 2.0,
      applicableBranchIds: List<String>.from(map['applicableBranchIds'] as List? ?? []),
      description: map['description'] as String?,
    );
  }
}

/// Evaluation result for a given date and branch against the holiday calendar
class HolidayEvaluationResult {
  final bool isHoliday;
  final EnterpriseHoliday? holiday;
  final double effectiveOvertimeMultiplier;
  final String statusDescription;

  const HolidayEvaluationResult({
    required this.isHoliday,
    this.holiday,
    this.effectiveOvertimeMultiplier = 1.0,
    required this.statusDescription,
  });
}
