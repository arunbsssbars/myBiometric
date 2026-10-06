import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/mobile_machine_anti_spoof_service.dart';

void main() {
  group('MobileMachineAntiSpoofService Tests', () {
    late MobileMachineAntiSpoofService service;

    setUp(() {
      service = MobileMachineAntiSpoofService();
    });

    test('issues valid anti-spoof token with natural gravity acceleration', () {
      final token = service.issueAntiSpoofToken(
        employeeId: 'EMP-007',
        enterpriseId: 'ENT-MI6',
        hardwareFingerprint: 'IMEI_HASH_883311',
        accelerometerMagnitude: 9.81,
      );

      expect(token.isMotionNatural, true);
      expect(token.signedAttestationPayload.isNotEmpty, true);

      final verified = service.verifyAntiSpoofToken(token);
      expect(verified, true);
    });

    test('detects unnatural movement magnitude (emulator or replay attack)', () {
      final token = service.issueAntiSpoofToken(
        employeeId: 'EMP-007',
        enterpriseId: 'ENT-MI6',
        hardwareFingerprint: 'IMEI_HASH_883311',
        accelerometerMagnitude: 0.0, // Static simulated zero gravity
      );

      expect(token.isMotionNatural, false);
      final verified = service.verifyAntiSpoofToken(token);
      expect(verified, false);
    });
  });
}
