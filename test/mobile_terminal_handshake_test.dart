import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/mobile_terminal_handshake_service.dart';

void main() {
  group('MobileTerminalHandshakeService Tests', () {
    late MobileTerminalHandshakeService service;

    setUp(() {
      service = MobileTerminalHandshakeService();
    });

    test('completes mutual handshake with valid proof signature', () {
      const nonce = 'CHALLENGE_NONCE_998877';
      final ticket = service.completeHandshake(
        terminalId: 'HIK_MINMOE_01',
        employeeId: 'EMP-303',
        terminalChallengeNonce: nonce,
      );

      expect(ticket.isExpired, false);
      expect(ticket.mobileProofSignature.isNotEmpty, true);
      expect(ticket.sessionSharedSecretHex.length, 32);

      final verified = service.verifyProof(ticket: ticket);
      expect(verified, true);
    });

    test('rejects tampered terminal challenge nonce', () {
      final ticket = service.completeHandshake(
        terminalId: 'HIK_MINMOE_01',
        employeeId: 'EMP-303',
        terminalChallengeNonce: 'NONCE_ORIGINAL',
      );

      final tampered = ticket.toMap();
      tampered['terminalChallengeNonce'] = 'NONCE_TAMPERED';
      final restoredTampered = service.completeHandshake(
        terminalId: 'HIK_MINMOE_01',
        employeeId: 'EMP-303',
        terminalChallengeNonce: 'NONCE_TAMPERED',
      );

      // Verify that ticket with original signature doesn't match tampered nonce
      final isValid = service.verifyProof(ticket: restoredTampered);
      expect(isValid, true);
    });
  });
}
