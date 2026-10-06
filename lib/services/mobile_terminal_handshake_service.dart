import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/mobile_terminal_handshake_ticket.dart';

/// Service executing zero-trust mutual authentication handshake between mobile and physical machine
class MobileTerminalHandshakeService {
  /// Signs challenge nonce returned by physical machine to prove employee authenticity
  MobileTerminalHandshakeTicket completeHandshake({
    required String terminalId,
    required String employeeId,
    required String terminalChallengeNonce,
    String? masterSharedKey,
    Duration sessionLifetime = const Duration(minutes: 5),
  }) {
    final now = DateTime.now();
    final key = utf8.encode(masterSharedKey ?? 'ENTERPRISE_TERMINAL_MUTUAL_AUTH_KEY');
    
    // Compute HMAC proof
    final message = utf8.encode('$terminalId:$employeeId:$terminalChallengeNonce');
    final proof = Hmac(sha256, key).convert(message).toString();

    // Derived session secret for subsequent punch packet encryption
    final sessionKey = sha256.convert(utf8.encode('$proof:${now.millisecondsSinceEpoch}')).toString().substring(0, 32);

    return MobileTerminalHandshakeTicket(
      ticketId: 'TKT_${now.millisecondsSinceEpoch}',
      terminalId: terminalId,
      employeeId: employeeId,
      sessionSharedSecretHex: sessionKey,
      terminalChallengeNonce: terminalChallengeNonce,
      mobileProofSignature: proof,
      issuedAt: now,
      expiresAt: now.add(sessionLifetime),
    );
  }

  /// Verifies mobile proof signature on physical terminal side
  bool verifyProof({
    required MobileTerminalHandshakeTicket ticket,
    String? masterSharedKey,
  }) {
    if (ticket.isExpired) return false;
    final key = utf8.encode(masterSharedKey ?? 'ENTERPRISE_TERMINAL_MUTUAL_AUTH_KEY');
    final message = utf8.encode('${ticket.terminalId}:${ticket.employeeId}:${ticket.terminalChallengeNonce}');
    final expectedProof = Hmac(sha256, key).convert(message).toString();
    return expectedProof == ticket.mobileProofSignature;
  }
}
