import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/shift_bidding_marketplace_service.dart';
import 'package:mybiometric/views/shift_bidding_marketplace_card.dart';

void main() {
  group('ShiftBiddingMarketplaceService Suite', () {
    late ShiftBiddingMarketplaceService service;

    setUp(() {
      service = ShiftBiddingMarketplaceService();
      service.clearForTesting();
    });

    test('Publishes open shift and accepts bids from eligible staff', () {
      final listing = OpenShiftListing(
        shiftId: 'SHIFT_WEEKEND_01',
        enterpriseId: 'ENT_HOSPITAL',
        department: 'Emergency Care',
        roleRequired: 'Registered Nurse',
        startTime: DateTime(2026, 10, 10, 8, 0),
        endTime: DateTime(2026, 10, 10, 16, 0),
        shiftHours: 8.0,
        hourlyPremiumMultiplier: 1.5,
      );

      service.publishShift(listing);

      final bid1 = service.submitBid(
        shiftId: 'SHIFT_WEEKEND_01',
        userId: 'NURSE_JUNIOR',
        employeeName: 'Junior Nurse',
        seniorityYears: 2,
      );

      final bid2 = service.submitBid(
        shiftId: 'SHIFT_WEEKEND_01',
        userId: 'NURSE_SENIOR',
        employeeName: 'Senior Nurse',
        seniorityYears: 7,
      );

      expect(service.bids.length, equals(2));
      expect(bid1.status, equals(BidStatus.submitted));
      expect(bid2.status, equals(BidStatus.submitted));

      // Award shift by seniority
      final winnerId = service.awardShiftBySeniority('SHIFT_WEEKEND_01');
      expect(winnerId, equals('NURSE_SENIOR'));

      final updatedListing = service.listings.firstWhere((s) => s.shiftId == 'SHIFT_WEEKEND_01');
      expect(updatedListing.isOpen, isFalse);
      expect(updatedListing.awardedUserId, equals('NURSE_SENIOR'));

      final juniorBid = service.bids.firstWhere((b) => b.userId == 'NURSE_JUNIOR');
      expect(juniorBid.status, equals(BidStatus.rejected));
    });

    testWidgets('ShiftBiddingMarketplaceCard renders without overflow across viewports', (tester) async {
      final listing = OpenShiftListing(
        shiftId: 'TEST_SHIFT',
        enterpriseId: 'ENT_TEST',
        department: 'ICU Unit',
        roleRequired: 'Lead Specialist',
        startTime: DateTime(2026, 10, 10, 18, 0),
        endTime: DateTime(2026, 10, 11, 2, 0),
        shiftHours: 8.0,
        hourlyPremiumMultiplier: 2.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShiftBiddingMarketplaceCard(
              listing: listing,
              totalBids: 3,
              onBid: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('ICU Unit'), findsOneWidget);
      expect(find.text('OPEN BIDDING'), findsOneWidget);
      expect(find.text('Bid on Shift'), findsOneWidget);
    });
  });
}
