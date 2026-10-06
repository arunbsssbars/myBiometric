import '../domain/models/enterprise_holiday_calendar.dart';

/// Enterprise Holiday Calendar Management & Evaluation Engine
class HolidayCalendarService {
  /// Evaluates whether a date is a recognized holiday for an employee/branch
  static HolidayEvaluationResult evaluateDate({
    required List<EnterpriseHoliday> holidays,
    required DateTime date,
    String? branchId,
  }) {
    for (final holiday in holidays) {
      if (holiday.isSameDay(date)) {
        // Check branch applicability
        if (holiday.applicableBranchIds.isNotEmpty && branchId != null) {
          if (!holiday.applicableBranchIds.contains(branchId)) {
            continue; // Not applicable to this branch
          }
        }

        return HolidayEvaluationResult(
          isHoliday: true,
          holiday: holiday,
          effectiveOvertimeMultiplier: holiday.overtimeMultiplier,
          statusDescription: '${holiday.title} (${_getHolidayTypeLabel(holiday.type)})',
        );
      }
    }

    return const HolidayEvaluationResult(
      isHoliday: false,
      holiday: null,
      effectiveOvertimeMultiplier: 1.0,
      statusDescription: 'Regular Working Day',
    );
  }

  /// Returns upcoming holidays from a reference date
  static List<EnterpriseHoliday> getUpcomingHolidays({
    required List<EnterpriseHoliday> holidays,
    DateTime? fromDate,
    int limit = 5,
  }) {
    final reference = fromDate ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);

    final upcoming = holidays.where((h) {
      final hDate = DateTime(h.date.year, h.date.month, h.date.day);
      return !hDate.isBefore(today);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return upcoming.take(limit).toList();
  }

  /// Calculates total expected working days in a month excluding weekends and holidays
  static int calculateWorkingDaysInMonth({
    required int year,
    required int month,
    required List<EnterpriseHoliday> holidays,
    List<int> weekendDays = const [DateTime.saturday, DateTime.sunday],
    String? branchId,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int workingDays = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (weekendDays.contains(date.weekday)) {
        continue; // Skip weekend
      }

      final eval = evaluateDate(
        holidays: holidays,
        date: date,
        branchId: branchId,
      );

      if (!eval.isHoliday) {
        workingDays++;
      }
    }

    return workingDays;
  }

  static String _getHolidayTypeLabel(HolidayType type) {
    switch (type) {
      case HolidayType.mandatoryPublic:
        return 'Public Holiday';
      case HolidayType.regionalStatutory:
        return 'Regional Holiday';
      case HolidayType.floatingOptional:
        return 'Floating Holiday';
      case HolidayType.companyDeclared:
        return 'Company Declared';
    }
  }
}
