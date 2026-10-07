import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/commute_carbon_estimator_service.dart';
import 'package:mybiometric/views/commute_carbon_estimator_card.dart';

void main() {
  group('CommuteCarbonEstimatorService Suite', () {
    late CommuteCarbonEstimatorService service;

    setUp(() {
      service = CommuteCarbonEstimatorService();
      service.clearForTesting();
    });

    test('Calculates zero actual emissions and maximum savings on remote days', () {
      final remoteRecord = CommuteTripRecord(
        userId: 'USR_REMOTE',
        employeeName: 'Sarah Connor',
        department: 'Cybernetics',
        roundTripDistanceKm: 30.0,
        mode: CommuteMode.gasolineCar,
        isRemoteWorkDay: true,
        date: DateTime(2026, 10, 8),
      );

      // Baseline: 30km * 170g / 1000 = 5.1 kg
      expect(remoteRecord.baselineCo2Kg, equals(5.1));
      expect(remoteRecord.actualCo2Kg, equals(0.0));
      expect(remoteRecord.co2SavedKg, equals(5.1));
    });

    test('Calculates reduced emissions for public transit commute', () {
      final transitRecord = CommuteTripRecord(
        userId: 'USR_TRANSIT',
        employeeName: 'Kyle Reese',
        department: 'Cybernetics',
        roundTripDistanceKm: 20.0,
        mode: CommuteMode.publicTransit,
        isRemoteWorkDay: false,
        date: DateTime(2026, 10, 8),
      );

      // Baseline: 20km * 170g / 1000 = 3.4 kg
      // Actual: 20km * 35g / 1000 = 0.7 kg
      // Saved: 2.7 kg
      expect(transitRecord.actualCo2Kg, closeTo(0.7, 0.01));
      expect(transitRecord.co2SavedKg, closeTo(2.7, 0.01));
    });

    test('Aggregates departmental ESG report cleanly', () {
      service.recordCommute(
        CommuteTripRecord(
          userId: '1',
          employeeName: 'A',
          department: 'Engineering',
          roundTripDistanceKm: 20.0,
          mode: CommuteMode.bicycleWalking,
          isRemoteWorkDay: false,
          date: DateTime(2026, 10, 8),
        ),
      );

      service.recordCommute(
        CommuteTripRecord(
          userId: '2',
          employeeName: 'B',
          department: 'Engineering',
          roundTripDistanceKm: 25.0,
          mode: CommuteMode.gasolineCar,
          isRemoteWorkDay: false,
          date: DateTime(2026, 10, 8),
        ),
      );

      final esg = service.evaluateDepartmentEsg('Engineering');
      expect(esg.totalWorkDays, equals(2));
      expect(esg.greenCommuteRatePercentage, equals(50.0));
      expect(esg.totalCo2SavedKg, greaterThan(0.0));
    });

    testWidgets('CommuteCarbonEstimatorCard renders without overflow across viewports', (tester) async {
      const summary = DepartmentEsgSummary(
        department: 'Product Design',
        totalCo2SavedKg: 142.5,
        totalActualCo2Kg: 35.0,
        totalWorkDays: 20,
        remoteWorkDays: 10,
        greenCommuteRatePercentage: 80.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommuteCarbonEstimatorCard(
              summary: summary,
            ),
          ),
        ),
      );

      expect(find.textContaining('Product Design'), findsOneWidget);
      expect(find.text('80% GREEN'), findsOneWidget);
      expect(find.textContaining('142.5 kg'), findsOneWidget);
    });
  });
}
