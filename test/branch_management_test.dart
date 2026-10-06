import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/enterprise_branch.dart';
import 'package:mybiometric/services/branch_management_service.dart';

void main() {
  group('BranchManagementService & Multi-Branch Tests', () {
    final hq = EnterpriseBranch(
      branchId: 'branch-hq',
      enterpriseId: 'ent-1',
      name: 'Global Headquarters',
      code: 'HQ-BLR',
      latitude: 12.9715987,
      longitude: 77.5945627,
      geofenceRadiusMeters: 150.0,
      allowedWifiSsids: ['Office-Corp-5G', 'Office-Guest'],
      assignedTerminalIds: ['term-01', 'term-02'],
      createdAt: DateTime(2026, 1, 1),
    );

    final warehouse = EnterpriseBranch(
      branchId: 'branch-wh',
      enterpriseId: 'ent-1',
      name: 'Logistics Facility',
      code: 'WH-ELC',
      latitude: 12.8452,
      longitude: 77.6602,
      geofenceRadiusMeters: 250.0,
      allowedWifiSsids: ['Warehouse_Mesh'],
      assignedTerminalIds: ['term-wh-01'],
      createdAt: DateTime(2026, 1, 1),
    );

    test('Accurately computes Haversine distance between two coordinates', () {
      final dist = BranchManagementService.calculateDistanceMeters(
        lat1: hq.latitude,
        lon1: hq.longitude,
        lat2: warehouse.latitude,
        lon2: warehouse.longitude,
      );
      // Distance between Bangalore MG Road and Electronic City is ~15-16 km
      expect(dist, greaterThan(14000.0));
      expect(dist, lessThan(17000.0));
    });

    test('Finds nearest branch from given coordinates', () {
      final nearest = BranchManagementService.findNearestBranch(
        branches: [hq, warehouse],
        latitude: 12.9716, // right near HQ
        longitude: 77.5946,
      );
      expect(nearest?.branchId, equals('branch-hq'));
    });

    test('Evaluates location inside geofence with authorization', () {
      final eval = BranchManagementService.evaluateLocation(
        branches: [hq, warehouse],
        latitude: 12.9716,
        longitude: 77.5946,
        employeeAssignedBranchIds: ['branch-hq'],
      );
      expect(eval.isWithinGeofence, isTrue);
      expect(eval.isAuthorizedForEmployee, isTrue);
      expect(eval.matchedBranch?.branchId, equals('branch-hq'));
      expect(eval.reason, contains('Authorized at Global Headquarters'));
    });

    test('Rejects punch when employee is at unauthorized branch', () {
      final eval = BranchManagementService.evaluateLocation(
        branches: [hq, warehouse],
        latitude: 12.9716,
        longitude: 77.5946,
        employeeAssignedBranchIds: ['branch-wh'], // only authorized for warehouse
      );
      expect(eval.isWithinGeofence, isTrue);
      expect(eval.isAuthorizedForEmployee, isFalse);
      expect(eval.reason, contains('not authorized for this branch'));
    });

    test('Verifies Wi-Fi SSID matching normalized case and quotes', () {
      expect(
        BranchManagementService.verifyBranchWifi(
          branch: hq,
          currentSsid: '"Office-Corp-5G"',
        ),
        isTrue,
      );
      expect(
        BranchManagementService.verifyBranchWifi(
          branch: hq,
          currentSsid: 'Unknown_Coffee_Shop',
        ),
        isFalse,
      );
    });

    test('Serializes and deserializes EnterpriseBranch correctly', () {
      final map = hq.toMap();
      final revived = EnterpriseBranch.fromMap(map);
      expect(revived.branchId, equals(hq.branchId));
      expect(revived.name, equals(hq.name));
      expect(revived.code, equals(hq.code));
      expect(revived.allowedWifiSsids, equals(hq.allowedWifiSsids));
    });
  });
}
