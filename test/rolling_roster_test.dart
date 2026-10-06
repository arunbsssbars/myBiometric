import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/rolling_roster_pattern.dart';
import 'package:mybiometric_app/services/rolling_roster_service.dart';

void main() {
  group('RollingRosterService Tests', () {
    // 4 on, 4 off pattern
    final pattern4on4off = RollingRosterPattern(
      patternId: 'pat-4on-4off',
      enterpriseId: 'ent-1',
      name: '4-On 4-Off Shift Pattern',
      anchorStartDate: DateTime(2026, 10, 1),
      steps: [
        const ShiftPatternStep(dayIndex: 0, cycleType: ShiftCycleType.morning, shiftName: 'Day 1 Morning'),
        const ShiftPatternStep(dayIndex: 1, cycleType: ShiftCycleType.morning, shiftName: 'Day 2 Morning'),
        const ShiftPatternStep(dayIndex: 2, cycleType: ShiftCycleType.night, shiftName: 'Day 3 Night'),
        const ShiftPatternStep(dayIndex: 3, cycleType: ShiftCycleType.night, shiftName: 'Day 4 Night'),
        const ShiftPatternStep(dayIndex: 4, cycleType: ShiftCycleType.restDay, shiftName: 'Off Day 1'),
        const ShiftPatternStep(dayIndex: 5, cycleType: ShiftCycleType.restDay, shiftName: 'Off Day 2'),
        const ShiftPatternStep(dayIndex: 6, cycleType: ShiftCycleType.restDay, shiftName: 'Off Day 3'),
        const ShiftPatternStep(dayIndex: 7, cycleType: ShiftCycleType.restDay, shiftName: 'Off Day 4'),
      ],
    );

    test('Accurately projects shift on anchor start date', () {
      final res = RollingRosterService.projectShiftForDate(
        pattern: pattern4on4off,
        employeeId: 'emp-101',
        targetDate: DateTime(2026, 10, 1),
      );

      expect(res.cycleDayNumber, equals(1));
      expect(res.step.cycleType, equals(ShiftCycleType.morning));
      expect(res.step.shiftName, equals('Day 1 Morning'));
    });

    test('Projects rest day on 5th day of cycle', () {
      final res = RollingRosterService.projectShiftForDate(
        pattern: pattern4on4off,
        employeeId: 'emp-101',
        targetDate: DateTime(2026, 10, 5), // 4 days after anchor -> dayIndex 4
      );

      expect(res.cycleDayNumber, equals(5));
      expect(res.step.cycleType, equals(ShiftCycleType.restDay));
      expect(res.step.isRestDay, isTrue);
    });

    test('Cycles back to Day 1 after 8 full days', () {
      final res = RollingRosterService.projectShiftForDate(
        pattern: pattern4on4off,
        employeeId: 'emp-101',
        targetDate: DateTime(2026, 10, 9), // 8 days after anchor
      );

      expect(res.cycleDayNumber, equals(1));
      expect(res.step.cycleType, equals(ShiftCycleType.morning));
    });

    test('Generates projection list across multiple days', () {
      final range = RollingRosterService.projectScheduleRange(
        pattern: pattern4on4off,
        employeeId: 'emp-101',
        startDate: DateTime(2026, 10, 1),
        numberOfDays: 8,
      );

      expect(range.length, equals(8));
      expect(range[0].step.cycleType, equals(ShiftCycleType.morning));
      expect(range[2].step.cycleType, equals(ShiftCycleType.night));
      expect(range[4].step.cycleType, equals(ShiftCycleType.restDay));
    });

    test('Serializes and deserializes RollingRosterPattern cleanly', () {
      final map = pattern4on4off.toMap();
      final revived = RollingRosterPattern.fromMap(map);

      expect(revived.patternId, equals(pattern4on4off.patternId));
      expect(revived.cycleLengthDays, equals(8));
      expect(revived.steps.first.shiftName, equals('Day 1 Morning'));
    });
  });
}
