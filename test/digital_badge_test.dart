import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/digital_badge_service.dart';

void main() {
  group('DigitalBadgeService Tests', () {
    const secret = 'super_secret_enterprise_hmac_key';
    const entId = 'ent_999';
    const empId = 'EMP-007';

    test('Generates and successfully validates cryptographic badge token', () {
      final now = DateTime(2026, 10, 3, 10, 0, 0);
      final badge = DigitalBadgeService.generateBadge(
        enterpriseId: entId,
        employeeId: empId,
        secretKey: secret,
        validity: const Duration(minutes: 2),
        now: now,
      );

      final qrPayload = badge.encodeToQrPayload();
      expect(qrPayload, startsWith('$entId:$empId:'));

      final isValid = DigitalBadgeService.validateScannedBadge(
        qrPayload: qrPayload,
        secretKey: secret,
        expectedEnterpriseId: entId,
        verificationTime: now.add(const Duration(minutes: 1)),
      );

      expect(isValid, isTrue);
    });

    test('Rejects expired or tampered badge tokens', () {
      final now = DateTime(2026, 10, 3, 10, 0, 0);
      final badge = DigitalBadgeService.generateBadge(
        enterpriseId: entId,
        employeeId: empId,
        secretKey: secret,
        validity: const Duration(minutes: 2),
        now: now,
      );

      final qrPayload = badge.encodeToQrPayload();

      // Test expiration after 3 minutes
      final isExpired = DigitalBadgeService.validateScannedBadge(
        qrPayload: qrPayload,
        secretKey: secret,
        expectedEnterpriseId: entId,
        verificationTime: now.add(const Duration(minutes: 3)),
      );
      expect(isExpired, isFalse);

      // Test wrong secret / tampered
      final isTampered = DigitalBadgeService.validateScannedBadge(
        qrPayload: qrPayload,
        secretKey: 'wrong_secret_key',
        expectedEnterpriseId: entId,
        verificationTime: now.add(const Duration(seconds: 30)),
      );
      expect(isTampered, isFalse);
    });
  });
}
