import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/external_biometric_device.dart';
import 'package:mybiometric/domain/models/terminal_fleet_analytics.dart';
import 'package:mybiometric/services/terminal_fleet_analytics_service.dart';

void main() {
  group('Terminal Fleet Analytics & SLA Scoreboard Suite', () {
    final testDevices = [
      BiometricTerminalDevice(
        id: 'term_1',
        enterpriseId: 'ent_demo',
        name: 'Gate 1',
        modelName: 'DS-K1T343MWX',
        protocol: TerminalProtocol.hikvisionIsapi,
        ipAddress: '192.168.1.10',
        status: DeviceConnectionStatus.online,
        createdAt: DateTime(2026, 1, 1),
      ),
      BiometricTerminalDevice(
        id: 'term_2',
        enterpriseId: 'ent_demo',
        name: 'Gate 2',
        modelName: 'DS-K1T343MWX',
        protocol: TerminalProtocol.hikvisionIsapi,
        ipAddress: '192.168.1.11',
        status: DeviceConnectionStatus.online,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    final testEvents = [
      TerminalAttendanceEvent(
        eventId: 'EVT-1',
        deviceId: 'term_1',
        employeeId: 'EMP-1',
        timestamp: DateTime(2026, 10, 3, 9, 15),
        punchType: 'PUNCH_IN',
        authMode: DeviceAuthMode.face,
        similarityScore: 99.6,
      ),
      TerminalAttendanceEvent(
        eventId: 'EVT-2',
        deviceId: 'term_2',
        employeeId: 'EMP-2',
        timestamp: DateTime(2026, 10, 3, 9, 20),
        punchType: 'PUNCH_IN',
        authMode: DeviceAuthMode.face,
        similarityScore: 99.2,
      ),
      TerminalAttendanceEvent(
        eventId: 'EVT-3',
        deviceId: 'term_1',
        employeeId: 'EMP-3',
        timestamp: DateTime(2026, 10, 3, 10, 5),
        punchType: 'PUNCH_IN',
        authMode: DeviceAuthMode.card,
        similarityScore: 100.0,
      ),
    ];

    test('TerminalFleetAnalyticsReport serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 3, 12, 0);
      final report = TerminalFleetAnalyticsReport(
        enterpriseId: 'ent_demo',
        totalTerminals: 2,
        onlineTerminals: 2,
        fleetUptimePercent: 100.0,
        totalPunchesToday: 3,
        peakHour: 9,
        peakHourPunchCount: 2,
        averageFaceSimilarityScore: 99.4,
        hourlyThroughput: [
          const TerminalThroughputBucket(hourOfDay: 9, totalPunches: 2, faceMatches: 2),
          const TerminalThroughputBucket(hourOfDay: 10, totalPunches: 1, cardSwipes: 1),
        ],
        generatedAt: now,
      );

      final json = report.toJson();
      final reconstructed = TerminalFleetAnalyticsReport.fromJson(json);

      expect(reconstructed.totalTerminals, equals(2));
      expect(reconstructed.fleetUptimePercent, equals(100.0));
      expect(reconstructed.peakHour, equals(9));
      expect(reconstructed.totalPunchesToday, equals(3));
    });

    test('TerminalFleetAnalyticsService aggregates peak hours and metrics correctly', () {
      final report = TerminalFleetAnalyticsService.generateFleetReport(
        enterpriseId: 'ent_demo',
        devices: testDevices,
        todayEvents: testEvents,
      );

      expect(report.totalTerminals, equals(2));
      expect(report.onlineTerminals, equals(2));
      expect(report.fleetUptimePercent, equals(100.0));
      expect(report.totalPunchesToday, equals(3));
      expect(report.peakHour, equals(9)); // 9:00 AM has 2 punches
      expect(report.peakHourPunchCount, equals(2));
      expect(report.averageFaceSimilarityScore, equals(99.4));
    });
  });
}
