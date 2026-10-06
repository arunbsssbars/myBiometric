import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/enterprise_branch.dart';
import 'package:mybiometric/services/branch_location_service.dart';

void main() {
  group('Enterprise Branch & Multi-Location Geofence Suite', () {
    final hqBranch = EnterpriseBranch(
      id: 'branch_hq',
      enterpriseId: 'ent_corp',
      name: 'Headquarters Campus',
      code: 'HQ',
      address: '100 Silicon Way, Tech City',
      latitude: 37.7749,
      longitude: -122.4194,
      radiusMeters: 200.0,
      allowedWifiSsids: ['Acme-Corporate-5G', 'Acme-Guest'],
      createdAt: DateTime(2026, 1, 1),
    );

    final factoryBranch = EnterpriseBranch(
      id: 'branch_factory',
      enterpriseId: 'ent_corp',
      name: 'South Logistics Plant',
      code: 'PLANT-1',
      address: '500 Industrial Pkwy',
      latitude: 37.7000,
      longitude: -122.4000,
      radiusMeters: 350.0,
      allowedWifiSsids: ['Plant1-WLAN'],
      createdAt: DateTime(2026, 1, 1),
    );

    test('EnterpriseBranch serializes and calculates accurate Haversine distance', () {
      final json = hqBranch.toJson();
      final reconstructed = EnterpriseBranch.fromJson({
        ...json,
        'id': 'branch_hq',
      });

      expect(reconstructed.name, equals('Headquarters Campus'));
      expect(reconstructed.code, equals('HQ'));
      expect(reconstructed.radiusMeters, equals(200.0));

      // Test point 50 meters away
      final distance = hqBranch.distanceMetersTo(37.7753, -122.4194);
      expect(distance, lessThan(100.0));
    });

    test('BranchLocationService allows punch inside branch radius', () {
      final res = BranchLocationService.evaluateLocation(
        branches: [hqBranch, factoryBranch],
        userLat: 37.7750,
        userLng: -122.4195,
      );

      expect(res.isWithinAnyBranch, isTrue);
      expect(res.matchingBranch?.id, equals('branch_hq'));
      expect(res.verifiedViaWifi, isFalse);
    });

    test('BranchLocationService allows punch matching branch Wi-Fi SSID even if GPS drifts', () {
      final res = BranchLocationService.evaluateLocation(
        branches: [hqBranch, factoryBranch],
        userLat: 37.8000, // GPS is 3km away
        userLng: -122.4000,
        connectedWifiSsid: 'Acme-Corporate-5G',
      );

      expect(res.isWithinAnyBranch, isTrue);
      expect(res.matchingBranch?.id, equals('branch_hq'));
      expect(res.verifiedViaWifi, isTrue);
    });

    test('BranchLocationService rejects punch outside all branch boundaries', () {
      final res = BranchLocationService.evaluateLocation(
        branches: [hqBranch, factoryBranch],
        userLat: 37.9000,
        userLng: -122.3000,
      );

      expect(res.isWithinAnyBranch, isFalse);
      expect(res.statusMessage, contains('Outside authorized perimeter'));
    });
  });
}
