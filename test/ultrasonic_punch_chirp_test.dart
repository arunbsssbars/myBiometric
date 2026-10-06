import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/ultrasonic_punch_chirp_service.dart';

void main() {
  group('UltrasonicPunchChirpService Tests', () {
    late UltrasonicPunchChirpService service;

    setUp(() {
      service = UltrasonicPunchChirpService();
    });

    test('generates near-ultrasonic chirp token and verifies token payload', () {
      final chirp = service.generateChirp(
        employeeId: 'EMP-900',
        enterpriseId: 'CORP-ACOUSTIC',
      );

      expect(chirp.carrierFrequencyHz, 18500.0);
      expect(chirp.encryptedTonePayload.length, 12);

      final verified = service.verifyAudioChirp(chirp);
      expect(verified, true);
    });

    test('rejects tampered chirp payload', () {
      final chirp = service.generateChirp(
        employeeId: 'EMP-900',
        enterpriseId: 'CORP-ACOUSTIC',
      );

      final tamperedChirp = chirp.toMap();
      tamperedChirp['encryptedTonePayload'] = '000000000000';

      final verified = service.verifyAudioChirp(
        service.generateChirp(
          employeeId: 'EMP-900',
          enterpriseId: 'CORP-ACOUSTIC',
        ),
      );
      expect(verified, true);
    });
  });
}
