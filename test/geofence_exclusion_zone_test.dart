import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/geofence_exclusion_zone_service.dart';
import 'package:mybiometric/views/geofence_exclusion_zone_card.dart';

void main() {
  group('GeofenceExclusionZoneService Suite', () {
    late GeofenceExclusionZoneService service;

    setUp(() {
      service = GeofenceExclusionZoneService();
      service.clearForTesting();
    });

    final testZone = ExclusionPolygonZone(
      id: 'ZONE_PARKING_01',
      enterpriseId: 'ENT_CORP',
      branchId: 'BR_HQ',
      name: 'South Parking Lot Exclusion Zone',
      reason: 'No attendance punch allowed outside office lobby perimeter',
      vertices: [
        const GeoCoordinate(latitude: 12.9710, longitude: 77.5940),
        const GeoCoordinate(latitude: 12.9710, longitude: 77.5950),
        const GeoCoordinate(latitude: 12.9700, longitude: 77.5950),
        const GeoCoordinate(latitude: 12.9700, longitude: 77.5940),
      ],
      isActive: true,
      createdAt: DateTime.now(),
    );

    test('Accurately detects points inside the exclusion polygon using ray-casting', () {
      service.registerZone(testZone);

      // Point safely inside the box
      final insideViolated = service.findViolatedExclusionZone(
        enterpriseId: 'ENT_CORP',
        latitude: 12.9705,
        longitude: 77.5945,
      );
      expect(insideViolated, isNotNull);
      expect(insideViolated!.id, equals('ZONE_PARKING_01'));

      // Point outside the box
      final outsideViolated = service.findViolatedExclusionZone(
        enterpriseId: 'ENT_CORP',
        latitude: 12.9720,
        longitude: 77.5960,
      );
      expect(outsideViolated, isNull);
    });

    test('Ignores inactive exclusion zones', () {
      final inactiveZone = ExclusionPolygonZone(
        id: 'ZONE_INACTIVE',
        enterpriseId: 'ENT_CORP',
        branchId: 'BR_HQ',
        name: 'Temporary Inactive Zone',
        reason: 'Maintenance Finished',
        vertices: testZone.vertices,
        isActive: false,
        createdAt: DateTime.now(),
      );
      service.registerZone(inactiveZone);

      final violation = service.findViolatedExclusionZone(
        enterpriseId: 'ENT_CORP',
        latitude: 12.9705,
        longitude: 77.5945,
      );
      expect(violation, isNull);
    });

    test('Records violation event and serializes correctly', () {
      service.registerZone(testZone);

      final event = service.recordViolation(
        userId: 'USR_007',
        employeeName: 'James Bond',
        zone: testZone,
        latitude: 12.9705,
        longitude: 77.5945,
      );

      expect(service.violations.length, equals(1));
      expect(event.employeeName, equals('James Bond'));
      expect(event.zoneId, equals('ZONE_PARKING_01'));

      final json = event.toJson();
      expect(json['userId'], equals('USR_007'));
      expect(json['zoneName'], equals(testZone.name));
    });

    testWidgets('GeofenceExclusionZoneCard renders without overflow across viewports', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeofenceExclusionZoneCard(
              zone: testZone,
              violationCount: 4,
              onToggleActive: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('South Parking Lot Exclusion Zone'), findsOneWidget);
      expect(find.text('RESTRICTED'), findsOneWidget);
      expect(find.textContaining('4 Vertices'), findsOneWidget);
    });
  });
}
