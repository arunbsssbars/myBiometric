import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/incident_root_cause_diagnosis_service.dart';
import 'package:mybiometric/views/incident_root_cause_diagnosis_card.dart';

void main() {
  group('IncidentRootCauseDiagnosisService Suite', () {
    late IncidentRootCauseDiagnosisService service;

    setUp(() {
      service = IncidentRootCauseDiagnosisService();
    });

    test('Diagnoses network flapping and provides Ethernet remediation', () {
      final finding = service.diagnoseTerminalState(
        deviceId: 'TERM_GATE_05',
        pingLatencyMs: 650.0,
        packetLossPercentage: 35.0,
        cameraLux: 200.0,
        internalTempCelsius: 30.0,
        consecutiveFailedRecognitions: 0,
      );

      expect(finding.category, equals(IncidentCategory.networkPartition));
      expect(finding.confidenceScore, greaterThan(0.9));
      expect(finding.rootCauseTitle, contains('Gateway Flapping'));
      expect(finding.remediationSteps.first, contains('switch port'));
    });

    test('Diagnoses low light condition when recognition failures occur under 30 lux', () {
      final finding = service.diagnoseTerminalState(
        deviceId: 'TERM_BASEMENT_01',
        pingLatencyMs: 25.0,
        packetLossPercentage: 0.0,
        cameraLux: 15.0, // Dark environment
        internalTempCelsius: 22.0,
        consecutiveFailedRecognitions: 4,
      );

      expect(finding.category, equals(IncidentCategory.sensorDegradation));
      expect(finding.confidenceScore, greaterThan(0.8));
      expect(finding.rootCauseTitle, contains('Optical Illumination'));
      expect(finding.remediationSteps.first, contains('infrared (IR)'));
    });

    testWidgets('IncidentRootCauseDiagnosisCard renders without overflow across viewports', (tester) async {
      final finding = DiagnosticFinding(
        findingId: 'diag_test',
        deviceId: 'TERM_NORTH_01',
        category: IncidentCategory.networkPartition,
        confidenceScore: 0.95,
        rootCauseTitle: 'Upstream LAN Congestion',
        explanation: 'Average ping latency reached 750ms with 40% packet loss.',
        remediationSteps: const ['Verify switch port configuration'],
        analyzedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncidentRootCauseDiagnosisCard(
              finding: finding,
            ),
          ),
        ),
      );

      expect(find.text('Upstream LAN Congestion'), findsOneWidget);
      expect(find.text('95% CONFIDENCE'), findsOneWidget);
      expect(find.textContaining('TERM_NORTH_01'), findsOneWidget);
    });
  });
}
