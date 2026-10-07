import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/shift_grace_period_rounding_service.dart';
import 'package:mybiometric/views/shift_grace_period_rounding_card.dart';

void main() {
  group('ShiftGracePeriodRoundingService Suite', () {
    late ShiftGracePeriodRoundingService service;

    setUp(() {
      service = ShiftGracePeriodRoundingService();
    });

    const policy = ShiftGraceRulePolicy(
      policyId: 'POL_FLSA_01',
      enterpriseId: 'ENT_FLSA',
      interval: RoundingInterval.sevenMinuteFLSA,
      gracePeriodArrivalMinutes: 5,
      gracePeriodDepartureMinutes: 5,
    );

    test('Applies grace period forgiveness when arriving 3 minutes after shift start', () {
      final scheduledStart = DateTime(2026, 10, 8, 9, 0);
      final actualPunch = DateTime(2026, 10, 8, 9, 3); // 3 mins late (<= 5 min grace)

      final result = service.calculateRoundedPunch(
        actualPunchTime: actualPunch,
        scheduledShiftTime: scheduledStart,
        policy: policy,
        isArrival: true,
      );

      expect(result.isGracePeriodApplied, isTrue);
      expect(result.roundedTimestamp, equals(scheduledStart));
      expect(result.differenceMinutes, equals(-3));
    });

    test('Applies 7-minute rule rounding down for 9:07 AM', () {
      final scheduledStart = DateTime(2026, 10, 8, 9, 0);
      final actualPunch = DateTime(2026, 10, 8, 9, 7); // 7 mins past block (rounds down to 9:00)

      final result = service.calculateRoundedPunch(
        actualPunchTime: actualPunch,
        scheduledShiftTime: scheduledStart,
        policy: policy,
        isArrival: false, // Normal punch outside grace
      );

      expect(result.isGracePeriodApplied, isFalse);
      expect(result.roundedTimestamp.minute, equals(0));
    });

    test('Applies 7-minute rule rounding up for 9:08 AM', () {
      final scheduledStart = DateTime(2026, 10, 8, 9, 0);
      final actualPunch = DateTime(2026, 10, 8, 9, 8); // 8 mins past block (rounds up to 9:15)

      final result = service.calculateRoundedPunch(
        actualPunchTime: actualPunch,
        scheduledShiftTime: scheduledStart,
        policy: policy,
        isArrival: false,
      );

      expect(result.isGracePeriodApplied, isFalse);
      expect(result.roundedTimestamp.minute, equals(15));
    });

    testWidgets('ShiftGracePeriodRoundingCard renders without overflow across viewports', (tester) async {
      final result = RoundedPunchResult(
        rawTimestamp: DateTime(2026, 10, 8, 9, 3),
        roundedTimestamp: DateTime(2026, 10, 8, 9, 0),
        isGracePeriodApplied: true,
        differenceMinutes: -3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShiftGracePeriodRoundingCard(
              result: result,
              label: 'Morning Shift Arrival',
            ),
          ),
        ),
      );

      expect(find.text('Morning Shift Arrival'), findsOneWidget);
      expect(find.text('GRACE FORGIVEN'), findsOneWidget);
      expect(find.textContaining('Raw: 09:03 ➔ Rounded: 09:00'), findsOneWidget);
    });
  });
}
