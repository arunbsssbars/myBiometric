import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/terminal_automation_rule.dart';

void main() {
  group('Terminal Scheduled Automation & Jitter Engine Suite', () {
    final testRule = TerminalAutomationRule(
      id: 'rule_101',
      enterpriseId: 'ent_demo',
      employeeId: 'EMP-7712',
      employeeName: 'Alex Rivera',
      preferredTerminalId: 'term_hq_front',
      shiftStartTime: '09:00',
      shiftEndTime: '18:00',
      activeWeekdays: [1, 2, 3, 4, 5],
      jitterMinutes: 4,
      autoPunchIn: true,
      autoPunchOut: true,
      createdAt: DateTime(2026, 10, 1),
    );

    test('TerminalAutomationRule serializes and deserializes accurately', () {
      final json = testRule.toJson();
      final reconstructed = TerminalAutomationRule.fromJson(json);

      expect(reconstructed.id, equals('rule_101'));
      expect(reconstructed.employeeName, equals('Alex Rivera'));
      expect(reconstructed.shiftStartTime, equals('09:00'));
      expect(reconstructed.shiftEndTime, equals('18:00'));
      expect(reconstructed.jitterMinutes, equals(4));
      expect(reconstructed.activeWeekdays, equals([1, 2, 3, 4, 5]));
    });

    test('computeRealisticPunchTime applies jitter variance within configured boundary', () {
      final baseDate = DateTime(2026, 10, 2, 0, 0);

      // Check 10 different random seeds
      for (int seed = 1; seed <= 10; seed++) {
        final punchInTime = testRule.computeRealisticPunchTime(baseDate, '09:00', seed: seed);
        final nominalTime = DateTime(2026, 10, 2, 9, 0);

        final differenceSeconds = punchInTime.difference(nominalTime).inSeconds.abs();
        expect(differenceSeconds, lessThanOrEqualTo(4 * 60)); // Maximum jitter is 4 minutes
      }
    });

    test('computeRealisticPunchTime handles zero jitter strictly', () {
      final zeroJitterRule = testRule.copyWith(jitterMinutes: 0);
      final baseDate = DateTime(2026, 10, 2, 0, 0);

      final punchInTime = zeroJitterRule.computeRealisticPunchTime(baseDate, '09:00', seed: 42);
      expect(punchInTime.hour, equals(9));
      expect(punchInTime.minute, equals(0));
      expect(punchInTime.second, equals(0));
    });
  });
}
