import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/first_responder_roster_service.dart';
import 'package:mybiometric/views/first_responder_roster_card.dart';

void main() {
  group('FirstResponderRosterService Suite', () {
    late FirstResponderRosterService service;

    setUp(() {
      service = FirstResponderRosterService();
      service.clearForTesting();
    });

    test('Identifies safe quorum when both CPR and Fire Warden are on site', () {
      service.registerResponder(
        const FirstResponderProfile(
          userId: 'USR_MED_01',
          employeeName: 'Dr. John Watson',
          department: 'Medical',
          contactPhone: '+1-555-0100',
          certifications: {CriticalSkillType.cprCertified, CriticalSkillType.firstAid},
        ),
      );

      service.registerResponder(
        const FirstResponderProfile(
          userId: 'USR_FIRE_01',
          employeeName: 'Captain Miller',
          department: 'Facilities',
          contactPhone: '+1-555-0101',
          certifications: {CriticalSkillType.fireWarden, CriticalSkillType.evacuationMarshal},
        ),
      );

      // Both are punched in
      final quorum = service.evaluateOnSiteSafetyQuorum(
        enterpriseId: 'ENT_HQ',
        currentlyPunchedInUserIds: {'USR_MED_01', 'USR_FIRE_01'},
      );

      expect(quorum.hasMinimumSafetyQuorum, isTrue);
      expect(quorum.cprCertifiedCount, equals(1));
      expect(quorum.fireWardenCount, equals(1));
      expect(quorum.totalOnSiteResponders, equals(2));
    });

    test('Flags deficit alert when fire warden is absent', () {
      service.registerResponder(
        const FirstResponderProfile(
          userId: 'USR_MED_01',
          employeeName: 'Dr. John Watson',
          department: 'Medical',
          contactPhone: '+1-555-0100',
          certifications: {CriticalSkillType.cprCertified},
        ),
      );

      // Only medical staff is punched in
      final quorum = service.evaluateOnSiteSafetyQuorum(
        enterpriseId: 'ENT_HQ',
        currentlyPunchedInUserIds: {'USR_MED_01'},
      );

      expect(quorum.hasMinimumSafetyQuorum, isFalse);
      expect(quorum.cprCertifiedCount, equals(1));
      expect(quorum.fireWardenCount, equals(0));
    });

    testWidgets('FirstResponderRosterCard renders without overflow across viewports', (tester) async {
      const summary = OnSiteFirstResponderSummary(
        enterpriseId: 'ENT_HQ',
        totalOnSiteResponders: 3,
        cprCertifiedCount: 2,
        fireWardenCount: 1,
        hasMinimumSafetyQuorum: true,
        activeResponders: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FirstResponderRosterCard(
              summary: summary,
            ),
          ),
        ),
      );

      expect(find.text('Emergency Safety Quorum'), findsOneWidget);
      expect(find.text('SAFE QUORUM'), findsOneWidget);
      expect(find.textContaining('3 Certified Staff Present'), findsOneWidget);
    });
  });
}
