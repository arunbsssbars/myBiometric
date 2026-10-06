import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/mobile_optical_qr_punch_token.dart';

/// Service synthesizing rotating optical QR tokens displayed on mobile app to present before machine
class MobileOpticalQrPunchService {
  MobileOpticalQrPunchService._internal();
  static final MobileOpticalQrPunchService instance = MobileOpticalQrPunchService._internal();

  /// Generates a fresh 45-second dynamic QR token with cryptographic HMAC-SHA256 signature
  MobileOpticalQrPunchToken generatePunchToken({
    required String employeeId,
    required String enterpriseId,
    required String punchType,
    required String secretKey,
    String? boundDeviceId,
    int validitySeconds = 45,
  }) {
    final now = DateTime.now();
    final expires = now.add(Duration(seconds: validitySeconds));
    final windowIndex = now.millisecondsSinceEpoch ~/ (validitySeconds * 1000);

    // Deterministic HMAC signature over employeeId + windowIndex
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode('$enterpriseId:$employeeId:$punchType:$windowIndex')).toString();

    return MobileOpticalQrPunchToken(
      tokenId: 'qr_${now.millisecondsSinceEpoch}',
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      punchType: punchType,
      issuedAt: now,
      expiresAt: expires,
      totpSignature: digest,
      boundDeviceId: boundDeviceId,
    );
  }

  /// Encodes token into standard JSON string rendered into QR matrix
  String formatQrCodePayload(MobileOpticalQrPunchToken token) {
    return jsonEncode({
      't': 'BIOMETRIC_MACHINE_PUNCH',
      'id': token.tokenId,
      'emp': token.employeeId,
      'ent': token.enterpriseId,
      'type': token.punchType,
      'exp': token.expiresAt.millisecondsSinceEpoch ~/ 1000,
      'sig': token.totpSignature.substring(0, 16),
    });
  }

  /// Verifies machine scan authenticity
  bool verifyScannedToken({
    required String qrPayloadString,
    required String secretKey,
  }) {
    try {
      final data = jsonDecode(qrPayloadString) as Map<String, dynamic>;
      if (data['t'] != 'BIOMETRIC_MACHINE_PUNCH') return false;

      final expEpoch = data['exp'] as int;
      final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowEpoch > expEpoch) return false;

      final ent = data['ent'] as String;
      final emp = data['emp'] as String;
      final type = data['type'] as String;
      final sig = data['sig'] as String;

      // Check current and previous 45s window
      final currentWindow = DateTime.now().millisecondsSinceEpoch ~/ (45 * 1000);
      for (final w in [currentWindow, currentWindow - 1]) {
        final hmac = Hmac(sha256, utf8.encode(secretKey));
        final expected = hmac.convert(utf8.encode('$ent:$emp:$type:$w')).toString();
        if (expected.startsWith(sig)) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
