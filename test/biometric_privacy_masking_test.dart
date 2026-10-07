import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/biometric_privacy_masking_service.dart';
import 'package:mybiometric/views/biometric_privacy_masking_card.dart';

void main() {
  group('BiometricPrivacyMaskingService Suite', () {
    late BiometricPrivacyMaskingService service;

    setUp(() {
      service = BiometricPrivacyMaskingService();
    });

    test('Anonymizes raw embedding and preserves internal angle similarity', () {
      final v1 = [0.12, 0.45, -0.22, 0.88, 0.15];
      final v2 = [0.10, 0.44, -0.20, 0.85, 0.14]; // Very similar to v1

      final masked1 = service.anonymizeTemplate(
        templateId: 'tmpl_1',
        userId: 'USR_PRIV_01',
        enterpriseId: 'ENT_PRIV',
        rawVector: v1,
      );

      final masked2 = service.anonymizeTemplate(
        templateId: 'tmpl_2',
        userId: 'USR_PRIV_01',
        enterpriseId: 'ENT_PRIV',
        rawVector: v2,
      );

      expect(masked1.perturbedVector.length, equals(v1.length));
      expect(masked1.projectionSaltHash.isNotEmpty, isTrue);

      final sim = service.compareMaskedTemplates(
        masked1.perturbedVector,
        masked2.perturbedVector,
      );

      // Orthogonal sign perturbation preserves cosine metric
      expect(sim, greaterThan(0.95));
    });

    testWidgets('BiometricPrivacyMaskingCard renders without overflow across viewports', (tester) async {
      final template = MaskedBiometricTemplate(
        templateId: 'tmpl_test',
        userId: 'USR_TEST',
        enterpriseId: 'ENT_TEST',
        perturbedVector: List.filled(128, 0.5),
        projectionSaltHash: 'a1b2c3d4e5f67890',
        complianceLevel: PrivacyPolicyComplianceLevel.gdprStrict,
        createdTimestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiometricPrivacyMaskingCard(
              template: template,
            ),
          ),
        ),
      );

      expect(find.text('Zero-Knowledge Biometric Profile'), findsOneWidget);
      expect(find.text('GDPRSTRICT'), findsOneWidget);
      expect(find.textContaining('Vector Dimensions: 128'), findsOneWidget);
    });
  });
}
