import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/enterprise_holiday_calendar.dart';
import 'package:mybiometric/services/holiday_calendar_service.dart';

void main() {
  group('HolidayCalendarService Tests', () {
    final holidays = [
      EnterpriseHoliday(
        holidayId: 'hol-new-year',
        enterpriseId: 'ent-1',
        title: "New Year's Day",
        date: DateTime(2026, 1, 1),
        type: HolidayType.mandatoryPublic,
        overtimeMultiplier: 2.0,
      ),
      EnterpriseHoliday(
        holidayId: 'hol-regional',
        enterpriseId: 'ent-1',
        title: 'State Foundation Day',
        date: DateTime(2026, 11, 1),
        type: HolidayType.regionalStatutory,
        applicableBranchIds: ['branch-blr'],
        overtimeMultiplier: 2.5,
      ),
      EnterpriseHoliday(
        holidayId: 'hol-christmas',
        enterpriseId: 'ent-1',
        title: 'Christmas Day',
        date: DateTime(2026, 12, 25),
        type: HolidayType.mandatoryPublic,
        overtimeMultiplier: 2.0,
      ),
    ];

    test('Correctly identifies declared holiday and applies overtime multiplier', () {
      final eval = HolidayCalendarService.evaluateDate(
        holidays: holidays,
        date: DateTime(2026, 1, 1, 14, 30),
      );

      expect(eval.isHoliday, isTrue);
      expect(eval.holiday?.title, equals("New Year's Day"));
      expect(eval.effectiveOvertimeMultiplier, equals(2.0));
    });

    test('Honors regional holiday applicability per branch', () {
      final blrEval = HolidayCalendarService.evaluateDate(
        holidays: holidays,
        date: DateTime(2026, 11, 1),
        branchId: 'branch-blr',
      );
      expect(blrEval.isHoliday, isTrue);
      expect(blrEval.effectiveOvertimeMultiplier, equals(2.5));

      final delhiEval = HolidayCalendarService.evaluateDate(
        holidays: holidays,
        date: DateTime(2026, 11, 1),
        branchId: 'branch-delhi',
      );
      expect(delhiEval.isHoliday, isFalse);
      expect(delhiEval.effectiveOvertimeMultiplier, equals(1.0));
    });

    test('Returns upcoming holidays chronologically sorted', () {
      final upcoming = HolidayCalendarService.getUpcomingHolidays(
        holidays: holidays,
        fromDate: DateTime(2026, 6, 1),
      );

      expect(upcoming.length, equals(2));
      expect(upcoming.first.title, equals('State Foundation Day'));
      expect(upcoming.last.title, equals('Christmas Day'));
    });

    test('Calculates monthly working days excluding weekends and holidays', () {
      // January 2026 has 31 days. Jan 1 is Thursday (holiday).
      // Weekends: Jan 3-4, 10-11, 17-18, 24-25, 31 (9 weekend days).
      // 31 - 9 weekends = 22 weekdays. Jan 1 is holiday -> 21 working days.
      final workingDays = HolidayCalendarService.calculateWorkingDaysInMonth(
        year: 2026,
        month: 1,
        holidays: holidays,
      );

      expect(workingDays, equals(21));
    });

    test('Serializes and deserializes EnterpriseHoliday cleanly', () {
      final h = holidays.first;
      final map = h.toMap();
      final revived = EnterpriseHoliday.fromMap(map);

      expect(revived.holidayId, equals(h.holidayId));
      expect(revived.title, equals(h.title));
      expect(revived.overtimeMultiplier, equals(2.0));
    });
  });
}
