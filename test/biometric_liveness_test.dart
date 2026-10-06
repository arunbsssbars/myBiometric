import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/biometric_liveness_audit.dart';
import 'package:mybiometric/services/biometric_liveness_audit_service.dart';

void main() {
  group('BiometricLivenessAuditService Tests', () {
    test('Confirms live human when all 4 sensor modalities pass thresholds', () {
      final res = BiometricLivenessAuditService.evaluateLiveness(
        punchId: 'p-101',
        employeeId: 'emp-101',
        rgbScore: 0.92,
        irScore: 0.95,
        depthScore: 0.89,
        blinkScore: 0.85,
      );

      expect(res.isLiveHumanConfirmed, isTrue);
      expect(res.aggregateLivenessScore, greaterThan(0.90));
      expect(res.spoofProbability, lessThan(0.10));
      expect(res.vectors.length, equals(4));
      expect(res.rejectionReason, isEmpty);
    });

    test('Triggers hard veto on 2D flat photo print attack', () {
      final res = BiometricLivenessAuditService.evaluateLiveness(
        punchId: 'p-102',
        employeeId: 'emp-101',
        rgbScore: 0.85, // High resolution photo looks okay in 2D RGB
        irScore: 0.65,
        depthScore: 0.15, // Flat surface (< 0.40)
        blinkScore: 0.10, // Static photo cannot blink
      );

      expect(res.isLiveHumanConfirmed, isFalse);
      expect(res.rejectionReason, contains('2D Planar photo spoof detected'));
    });

    test('Triggers hard veto on electronic iPad screen replay attack', () {
      final res = BiometricLivenessAuditService.evaluateLiveness(
        punchId: 'p-103',
        employeeId: 'emp-101',
        rgbScore: 0.45, // Screen moiré
        irScore: 0.25, // Glass screen reflection (< 0.40)
        depthScore: 0.70,
        blinkScore: 0.60,
      );

      expect(res.isLiveHumanConfirmed, isFalse);
      expect(res.rejectionReason, contains('Synthetic material/screen reflection detected'));
    });

    test('Serializes and deserializes BiometricLivenessScorecard cleanly', () {
      final scorecard = BiometricLivenessAuditService.evaluateLiveness(
        punchId: 'p-104',
        employeeId: 'emp-101',
        rgbScore: 0.90,
        irScore: 0.90,
        depthScore: 0.90,
        blinkScore: 0.90,
      );

      final map = scorecard.toMap();
      final revived = BiometricLivenessScorecard.fromMap(map);

      expect(revived.punchId, equals(scorecard.punchId));
      expect(revived.isLiveHumanConfirmed, isTrue);
      expect(revived.vectors.length, equals(4));
    });
  });
}
