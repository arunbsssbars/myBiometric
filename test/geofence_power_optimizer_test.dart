import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/enterprise_branch.dart';
import 'package:mybiometric/domain/models/geofence_power_mode.dart';
import 'package:mybiometric/services/geofence_power_optimizer_service.dart';

void main() {
  group('GeofencePowerOptimizerService Tests', () {
    final branch = EnterpriseBranch(
      id: 'br_hq',
      enterpriseId: 'ent_demo',
      name: 'HQ Campus',
      code: 'BR-HQ',
      address: '100 Market St, San Francisco, CA',
      latitude: 37.7749,
      longitude: -122.4194,
      radiusMeters: 100.0,
      createdAt: DateTime(2026, 1, 1),
    );

    test('Selects highPrecision mode when within 300m of campus', () {
      // Very close (~50m away)
      final eval = GeofencePowerOptimizerService.evaluatePowerMode(
        userLat: 37.7752,
        userLng: -122.4194,
        branches: [branch],
      );

      expect(eval.recommendedPowerMode, equals(GeofencePowerMode.highPrecision));
      expect(eval.recommendedLocationIntervalSeconds, equals(10));
      expect(eval.nearestBranchId, equals('br_hq'));
    });

    test('Selects passiveLowPower mode when far away (> 5km)', () {
      // 10km away
      final eval = GeofencePowerOptimizerService.evaluatePowerMode(
        userLat: 37.8500,
        userLng: -122.4194,
        branches: [branch],
      );

      expect(eval.recommendedPowerMode, equals(GeofencePowerMode.passiveLowPower));
      expect(eval.recommendedLocationIntervalSeconds, equals(300));
    });
  });
}
