import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/visitor_badge_governor_service.dart';
import 'package:mybiometric/views/visitor_badge_governor_card.dart';

void main() {
  group('VisitorBadgeGovernorService Suite', () {
    late VisitorBadgeGovernorService service;

    setUp(() {
      service = VisitorBadgeGovernorService();
      service.clearForTesting();
    });

    test('Issues visitor badge and validates entry with correct PIN', () {
      final badge = service.issueBadge(
        enterpriseId: 'ENT_HQ',
        visitorName: 'Elon Musk',
        companyName: 'SpaceX',
        hostEmployeeName: 'Tony Stark',
        visitorType: VisitorType.client,
        temporaryPin: '9876',
        validDuration: const Duration(hours: 4),
      );

      expect(badge.status, equals(BadgeStatus.active));
      expect(badge.temporaryPin, equals('9876'));

      // Validate with right pin
      final valid = service.validateVisitorEntry(
        badgeId: badge.badgeId,
        enteredPin: '9876',
      );
      expect(valid, isTrue);

      // Validate with wrong pin
      final wrongPin = service.validateVisitorEntry(
        badgeId: badge.badgeId,
        enteredPin: '1111',
      );
      expect(wrongPin, isFalse);
    });

    test('Rejects entry after badge expiry duration', () {
      final badge = service.issueBadge(
        enterpriseId: 'ENT_HQ',
        visitorName: 'Contractor Bob',
        companyName: 'Acme HVAC',
        hostEmployeeName: 'Facility Mgr',
        visitorType: VisitorType.contractor,
        temporaryPin: '4321',
        validDuration: const Duration(hours: 2),
      );

      // 3 hours later (expired)
      final futureTime = DateTime.now().add(const Duration(hours: 3));

      final allowed = service.validateVisitorEntry(
        badgeId: badge.badgeId,
        enteredPin: '4321',
        currentTime: futureTime,
      );
      expect(allowed, isFalse);
    });

    test('Allows admin to revoke visitor badge prematurely', () {
      final badge = service.issueBadge(
        enterpriseId: 'ENT_HQ',
        visitorName: 'Sneaky Visitor',
        companyName: 'Unknown',
        hostEmployeeName: 'Front Desk',
        visitorType: VisitorType.vendor,
        temporaryPin: '5555',
      );

      final revoked = service.revokeBadge(badge.badgeId, 'Security breach');
      expect(revoked, isTrue);

      final allowed = service.validateVisitorEntry(
        badgeId: badge.badgeId,
        enteredPin: '5555',
      );
      expect(allowed, isFalse);
    });

    testWidgets('VisitorBadgeGovernorCard renders without overflow across viewports', (tester) async {
      final badge = VisitorAccessBadge(
        badgeId: 'vis_test',
        enterpriseId: 'ENT_HQ',
        visitorName: 'Grace Hopper',
        companyName: 'US Navy',
        hostEmployeeName: 'Admin',
        visitorType: VisitorType.client,
        temporaryPin: '1906',
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 6)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitorBadgeGovernorCard(
              badge: badge,
              onRevoke: () {},
            ),
          ),
        ),
      );

      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.textContaining('US Navy'), findsOneWidget);
      expect(find.text('Revoke'), findsOneWidget);
    });
  });
}
