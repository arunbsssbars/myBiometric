import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/per_diem_allowance_service.dart';
import 'package:mybiometric/views/per_diem_allowance_card.dart';

void main() {
  group('PerDiemAllowanceService Suite', () {
    late PerDiemAllowanceService service;

    setUp(() {
      service = PerDiemAllowanceService();
      service.clearForTesting();
    });

    final policy = PerDiemPolicy(
      id: 'POL_US',
      enterpriseId: 'ENT_GLOBAL',
      currencyCode: 'USD',
      minHoursForMealVoucher: 6.0,
      mealVoucherAmount: 18.0,
      minHoursForFullPerDiem: 10.0,
      fullPerDiemAmount: 50.0,
      nightShiftSurchargeEnabled: true,
      nightShiftSurchargeAmount: 15.0,
    );

    test('Qualifies for meal voucher when worked >= 6 hrs but < 10 hrs', () {
      final record = service.evaluateShiftAllowance(
        policy: policy,
        userId: 'USR_LUNCH',
        employeeName: 'John Doe',
        shiftDate: DateTime(2026, 10, 8),
        workedHours: 7.5,
        isNightShift: false,
      );

      expect(record.totalAllowance, equals(18.0));
      expect(record.qualificationReasons.first, contains('Meal Voucher'));
    });

    test('Qualifies for full per diem and night shift surcharge when applicable', () {
      final record = service.evaluateShiftAllowance(
        policy: policy,
        userId: 'USR_OVERNIGHT',
        employeeName: 'Jane Doe',
        shiftDate: DateTime(2026, 10, 8),
        workedHours: 11.0,
        isNightShift: true,
      );

      // 50.0 full per diem + 15.0 night shift surcharge = 65.0
      expect(record.totalAllowance, equals(65.0));
      expect(record.qualificationReasons.length, equals(2));
      expect(record.qualificationReasons[0], contains('Full Day Per Diem'));
      expect(record.qualificationReasons[1], contains('Night Shift Surcharge'));
    });

    test('Awards zero allowance for shifts under minimum meal threshold', () {
      final record = service.evaluateShiftAllowance(
        policy: policy,
        userId: 'USR_SHORT',
        employeeName: 'Short Shift',
        shiftDate: DateTime(2026, 10, 8),
        workedHours: 4.0,
        isNightShift: false,
      );

      expect(record.totalAllowance, equals(0.0));
      expect(record.qualificationReasons, isEmpty);
    });

    testWidgets('PerDiemAllowanceCard renders without overflow across viewports', (tester) async {
      final record = PerDiemDisbursementRecord(
        id: 'rec_card_test',
        enterpriseId: 'ENT_GLOBAL',
        userId: 'USR_TEST',
        employeeName: 'Bruce Wayne',
        shiftDate: DateTime(2026, 10, 8),
        workedHours: 12.0,
        isNightShift: true,
        totalAllowance: 65.0,
        currencyCode: 'USD',
        qualificationReasons: const ['Full Day Per Diem', 'Night Shift Surcharge'],
        generatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerDiemAllowanceCard(
              record: record,
            ),
          ),
        ),
      );

      expect(find.text('Bruce Wayne'), findsOneWidget);
      expect(find.text('USD 65.00'), findsOneWidget);
      expect(find.textContaining('Full Day Per Diem'), findsOneWidget);
    });
  });
}
