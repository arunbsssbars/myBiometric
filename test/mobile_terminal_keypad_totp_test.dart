import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/mobile_terminal_keypad_totp_service.dart';

void main() {
  group('MobileTerminalKeypadTotpService Tests', () {
    late MobileTerminalKeypadTotpService service;

    setUp(() {
      service = MobileTerminalKeypadTotpService();
    });

    test('generates 6-digit numeric PIN and verifies successfully', () {
      final totp = service.generateKeypadPin(
        employeeId: 'EMP-555',
        enterpriseId: 'CORP-TEST',
      );

      expect(totp.pinCode.length, 6);
      expect(int.tryParse(totp.pinCode) != null, true);
      expect(totp.isExpired, false);

      final verified = service.verifyKeypadPin(
        enteredPin: totp.pinCode,
        employeeId: 'EMP-555',
        enterpriseId: 'CORP-TEST',
      );
      expect(verified, true);
    });

    test('rejects incorrect keypad PIN', () {
      final verified = service.verifyKeypadPin(
        enteredPin: '999999',
        employeeId: 'EMP-555',
        enterpriseId: 'CORP-TEST',
      );
      expect(verified, false);
    });
  });
}
