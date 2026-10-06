import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/mobile_optical_qr_punch_service.dart';

void main() {
  group('MobileOpticalQrPunchService Suite', () {
    const enterpriseId = 'ent_corp';
    const employeeId = 'EMP1001';
    const secretKey = 'ENTERPRISE_HMAC_SECRET_KEY';

    test('Generates valid signed dynamic QR punch token', () {
      final token = MobileOpticalQrPunchService.instance.generatePunchToken(
        employeeId: employeeId,
        enterpriseId: enterpriseId,
        punchType: 'PUNCH_IN',
        secretKey: secretKey,
        validitySeconds: 45,
      );

      expect(token.employeeId, equals('EMP1001'));
      expect(token.punchType, equals('PUNCH_IN'));
      expect(token.isExpired, isFalse);
      expect(token.remainingSeconds, greaterThan(0));
      expect(token.totpSignature.isNotEmpty, isTrue);
    });

    test('Formats JSON QR payload and verifies authenticity', () {
      final token = MobileOpticalQrPunchService.instance.generatePunchToken(
        employeeId: employeeId,
        enterpriseId: enterpriseId,
        punchType: 'PUNCH_OUT',
        secretKey: secretKey,
        validitySeconds: 45,
      );

      final qrString = MobileOpticalQrPunchService.instance.formatQrCodePayload(token);
      final isValid = MobileOpticalQrPunchService.instance.verifyScannedToken(
        qrPayloadString: qrString,
        secretKey: secretKey,
      );

      expect(isValid, isTrue);

      final isTampered = MobileOpticalQrPunchService.instance.verifyScannedToken(
        qrPayloadString: qrString,
        secretKey: 'WRONG_SECRET_KEY',
      );
      expect(isTampered, isFalse);
    });
  });
}
