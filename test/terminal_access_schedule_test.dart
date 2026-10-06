import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/terminal_access_schedule.dart';

void main() {
  group('Terminal Access Schedule & Time-Zone Privilege Suite', () {
    test('Standard Office Hours schedule grants access during work hours and denies after hours', () {
      final schedule = TerminalAccessSchedule.standardOffice('ent-101');

      // Monday at 10:30 AM (Should be allowed)
      final mondayWorkHour = DateTime(2026, 9, 28, 10, 30); // 2026-09-28 is a Monday
      expect(schedule.isAccessAuthorized(mondayWorkHour), isTrue);

      // Monday at 21:30 (9:30 PM) (Should be denied for regular employee)
      final mondayLateNight = DateTime(2026, 9, 28, 21, 30);
      expect(schedule.isAccessAuthorized(mondayLateNight, isManager: false), isFalse);

      // Monday at 21:30 (9:30 PM) (Should be allowed for Manager override)
      expect(schedule.isAccessAuthorized(mondayLateNight, isManager: true), isTrue);

      // Sunday at 14:00 (Weekend closed)
      final sundayAfternoon = DateTime(2026, 10, 4, 14, 0); // Sunday
      expect(schedule.isAccessAuthorized(sundayAfternoon, isManager: false), isFalse);
    });

    test('TerminalAccessSchedule serializes and deserializes accurately with weekly windows', () {
      const schedule = TerminalAccessSchedule(
        id: 'sched-factory-night',
        enterpriseId: 'ent-101',
        name: 'Night Shift Access',
        type: TerminalScheduleType.customWeekly,
        allowManagerOverride: true,
        weeklyWindows: {
          1: [TimeSpanWindow(startHour: 22, startMinute: 0, endHour: 23, endMinute: 59)],
        },
      );

      final map = schedule.toMap();
      expect(map['id'], 'sched-factory-night');
      expect(map['type'], 'customWeekly');
      expect(map['weeklyWindows'], isA<Map>());

      final revived = TerminalAccessSchedule.fromMap(map, id: 'sched-factory-night');
      expect(revived.name, 'Night Shift Access');
      expect(revived.weeklyWindows[1]?.first.startHour, 22);
    });

    test('toHikvisionIsapiSchedule formats valid ISAPI structure', () {
      final schedule = TerminalAccessSchedule.standardOffice('ent-101');
      final isapiPayload = schedule.toHikvisionIsapiSchedule();

      expect(isapiPayload.containsKey('TimeSchedule'), isTrue);
      final scheduleBody = isapiPayload['TimeSchedule'] as Map<String, dynamic>;
      expect(scheduleBody['name'], contains('Standard Office Hours'));
      expect(scheduleBody['ScheduleDay'], isA<List>());
      final days = scheduleBody['ScheduleDay'] as List;
      expect(days.length, 7);
    });
  });
}
