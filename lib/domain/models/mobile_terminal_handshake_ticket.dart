import 'package:flutter/foundation.dart';

/// Cryptographic mutual authentication handshake between mobile app and physical terminal
@immutable
class MobileTerminalHandshakeTicket {
  final String ticketId;
  final String terminalId;
  final String employeeId;
  final String sessionSharedSecretHex;
  final String terminalChallengeNonce;
  final String mobileProofSignature;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const MobileTerminalHandshakeTicket({
    required this.ticketId,
    required this.terminalId,
    required this.employeeId,
    required this.sessionSharedSecretHex,
    required this.terminalChallengeNonce,
    required this.mobileProofSignature,
    required this.issuedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get remainingSeconds {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Map<String, dynamic> toMap() => {
        'ticketId': ticketId,
        'terminalId': terminalId,
        'employeeId': employeeId,
        'sessionSharedSecretHex': sessionSharedSecretHex,
        'terminalChallengeNonce': terminalChallengeNonce,
        'mobileProofSignature': mobileProofSignature,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory MobileTerminalHandshakeTicket.fromMap(Map<String, dynamic> map) =>
      MobileTerminalHandshakeTicket(
        ticketId: map['ticketId'] as String? ?? '',
        terminalId: map['terminalId'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        sessionSharedSecretHex: map['sessionSharedSecretHex'] as String? ?? '',
        terminalChallengeNonce: map['terminalChallengeNonce'] as String? ?? '',
        mobileProofSignature: map['mobileProofSignature'] as String? ?? '',
        issuedAt: map['issuedAt'] != null
            ? DateTime.tryParse(map['issuedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: map['expiresAt'] != null
            ? DateTime.tryParse(map['expiresAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
