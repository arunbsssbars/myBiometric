import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/mobile_virtual_nfc_badge.dart';

/// Service managing Host Card Emulation (HCE) to present smartphone as an RFID badge to terminals
class MobileNfcHceBridgeService {
  static const String enterpriseAid = 'F0010203040506';

  /// Generates a valid virtual card badge for the employee
  MobileVirtualNfcBadge issueVirtualBadge({
    required String employeeId,
    required String enterpriseId,
    String? secretKey,
    Duration validity = const Duration(hours: 12),
  }) {
    final now = DateTime.now();
    final expiresAt = now.add(validity);
    final key = utf8.encode(secretKey ?? 'ENTERPRISE_NFC_HCE_KEY');

    // Generate pseudo-UID (7 bytes hex, 14 hex chars)
    final uidDigest = sha256.convert(utf8.encode('$employeeId:$enterpriseId')).toString();
    final cardUid = uidDigest.substring(0, 14).toUpperCase();

    // Payload signature
    final payloadRaw = utf8.encode('$cardUid:$employeeId:$enterpriseId:${expiresAt.millisecondsSinceEpoch}');
    final sig = Hmac(sha256, key).convert(payloadRaw).toString().substring(0, 32);

    return MobileVirtualNfcBadge(
      cardUid: cardUid,
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      applicationIdentifier: enterpriseAid,
      encryptedCardPayload: sig,
      issuedAt: now,
      expiresAt: expiresAt,
      isHceActive: true,
    );
  }

  /// Processes an APDU command exchanged between the physical reader and mobile phone
  /// Returns response APDU bytes (hex string)
  String processApduCommand({
    required String apduCommandHex,
    required MobileVirtualNfcBadge badge,
  }) {
    final cmd = apduCommandHex.toUpperCase().replaceAll(' ', '');

    // Select AID command: '00A4040007' + AID + '00'
    if (cmd.startsWith('00A40400')) {
      // Return 9000 (Success)
      return '9000';
    }

    // Read Card ID command: '00B00000'
    if (cmd.startsWith('00B00000')) {
      final payloadData = '${badge.cardUid}:${badge.employeeId}';
      final hexData = utf8.encode(payloadData).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return '${hexData}9000';
    }

    // Unknown command -> 6D00 (Instruction not supported)
    return '6D00';
  }
}
