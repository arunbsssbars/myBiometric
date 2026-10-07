import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/multi_site_roving_presence_service.dart';
import 'package:mybiometric/views/multi_site_roving_presence_card.dart';

void main() {
  group('MultiSiteRovingPresenceService Suite', () {
    late MultiSiteRovingPresenceService service;

    setUp(() {
      service = MultiSiteRovingPresenceService();
    });

    test('Detects multi-site roving and computes transit duration accurately', () {
      final punches = [
        BranchPunchEvent(
          branchId: 'BR_HQ',
          branchName: 'Headquarters',
          timestamp: DateTime(2026, 10, 8, 9, 0),
          punchType: 'PUNCH_IN',
        ),
        BranchPunchEvent(
          branchId: 'BR_HQ',
          branchName: 'Headquarters',
          timestamp: DateTime(2026, 10, 8, 12, 0),
          punchType: 'PUNCH_OUT',
        ),
        BranchPunchEvent(
          branchId: 'BR_WAREHOUSE',
          branchName: 'Logistics Warehouse',
          timestamp: DateTime(2026, 10, 8, 12, 45), // 45 mins transit
          punchType: 'PUNCH_IN',
        ),
        BranchPunchEvent(
          branchId: 'BR_WAREHOUSE',
          branchName: 'Logistics Warehouse',
          timestamp: DateTime(2026, 10, 8, 17, 0),
          punchType: 'PUNCH_OUT',
        ),
      ];

      final record = service.evaluateDailyPresence(
        userId: 'USR_ROVING_01',
        employeeName: 'Clark Kent',
        date: DateTime(2026, 10, 8),
        punches: punches,
      );

      expect(record.isMultiSiteRoving, isTrue);
      expect(record.visitedBranchIds.length, equals(2));
      expect(record.transits.length, equals(1));
      expect(record.transits.first.transitDuration.inMinutes, equals(45));
      expect(record.totalTransitDuration.inMinutes, equals(45));
    });

    test('Identifies stationary presence at single site', () {
      final punches = [
        BranchPunchEvent(
          branchId: 'BR_HQ',
          branchName: 'Headquarters',
          timestamp: DateTime(2026, 10, 8, 9, 0),
          punchType: 'PUNCH_IN',
        ),
        BranchPunchEvent(
          branchId: 'BR_HQ',
          branchName: 'Headquarters',
          timestamp: DateTime(2026, 10, 8, 17, 0),
          punchType: 'PUNCH_OUT',
        ),
      ];

      final record = service.evaluateDailyPresence(
        userId: 'USR_STATIC_01',
        employeeName: 'Lois Lane',
        date: DateTime(2026, 10, 8),
        punches: punches,
      );

      expect(record.isMultiSiteRoving, isFalse);
      expect(record.visitedBranchIds.length, equals(1));
      expect(record.transits, isEmpty);
      expect(record.totalTransitDuration, equals(Duration.zero));
    });

    testWidgets('MultiSiteRovingPresenceCard renders without overflow across viewports', (tester) async {
      final record = EmployeeRovingDayRecord(
        userId: 'USR_ROVING_TEST',
        employeeName: 'Barry Allen',
        date: DateTime(2026, 10, 8),
        punchHistory: const [],
        transits: [
          InterBranchTransit(
            fromBranchId: 'BR_A',
            toBranchId: 'BR_B',
            transitDuration: const Duration(minutes: 30),
            departedAt: DateTime.now(),
            arrivedAt: DateTime.now(),
          ),
        ],
        visitedBranchIds: const {'BR_A', 'BR_B'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSiteRovingPresenceCard(
              record: record,
            ),
          ),
        ),
      );

      expect(find.text('Barry Allen'), findsOneWidget);
      expect(find.text('MULTI-SITE ROVING'), findsOneWidget);
      expect(find.textContaining('2 Facilities Visited'), findsOneWidget);
      expect(find.textContaining('30 mins'), findsOneWidget);
    });
  });
}
