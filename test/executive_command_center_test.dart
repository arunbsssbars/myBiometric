import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/executive_command_center_service.dart';
import 'package:mybiometric/views/executive_command_center_screen.dart';

void main() {
  group('ExecutiveCommandCenterService & Cockpit Suite', () {
    late ExecutiveCommandCenterService service;

    setUp(() {
      service = ExecutiveCommandCenterService();
    });

    test('Synthesizes operational cockpit metrics and computes fleet uptime percentage', () {
      final metrics = service.synthesizeMetrics(
        enterpriseId: 'ENT_GLOBAL_HQ',
        totalTerminals: 20,
        onlineTerminals: 19,
        totalEmployees: 500,
        onSiteEmployees: 320,
        punchesLastHour: 145,
        pendingRegularizations: 3,
        tamperAlerts: 0,
        averageConfidence: 0.97,
      );

      expect(metrics.totalTerminals, equals(20));
      expect(metrics.onlineTerminals, equals(19));
      expect(metrics.fleetUptimePercentage, equals(95.0));
      expect(metrics.isFleetHealthy, isTrue);
      expect(metrics.currentlyOnSiteCount, equals(320));
    });

    test('Flags fleet unhealthy when tamper alerts are active', () {
      final metrics = service.synthesizeMetrics(
        enterpriseId: 'ENT_GLOBAL_HQ',
        totalTerminals: 20,
        onlineTerminals: 20,
        totalEmployees: 500,
        onSiteEmployees: 320,
        punchesLastHour: 145,
        pendingRegularizations: 3,
        tamperAlerts: 1, // Active tamper alert
      );

      expect(metrics.isFleetHealthy, isFalse);
    });

    testWidgets('ExecutiveCommandCenterScreen renders across all viewports without overflow', (tester) async {
      final metrics = ExecutiveCockpitMetrics(
        enterpriseId: 'ENT_ACME_CORP',
        totalTerminals: 10,
        onlineTerminals: 10,
        fleetUptimePercentage: 100.0,
        totalEnrolledEmployees: 250,
        currentlyOnSiteCount: 180,
        activePunchesLastHour: 95,
        pendingRegularizations: 2,
        activeTamperAlerts: 0,
        averageRecognitionConfidence: 0.98,
        aggregatedAt: DateTime.now(),
      );

      // Test standard mobile width (393px)
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ExecutiveCommandCenterScreen(
            metrics: metrics,
          ),
        ),
      );

      expect(find.textContaining('ENT_ACME_CORP'), findsOneWidget);
      expect(find.text('Fleet Fully Operational'), findsOneWidget);
      expect(find.text('On-Site Staff'), findsOneWidget);
      expect(find.text('180'), findsOneWidget);
      expect(find.text('98.0%'), findsOneWidget);
    });
  });
}
