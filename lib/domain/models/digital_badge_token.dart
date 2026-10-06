import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Represents a digitally signed dynamic QR badge token for employee kiosk scanning
class DigitalBadgeToken {
  final String employeeId;
  final String enterpriseId;
  final int issuedTimestampSeconds;
  final int expiryTimestampSeconds;
  final String signature;

  const DigitalBadgeToken({
    required this.employeeId,
    required this.enterpriseId,
    required this.issuedTimestampSeconds,
    required this.expiryTimestampSeconds,
    required this.signature,
  });

  bool isExpired({DateTime? currentTime}) {
    final nowSeconds = (currentTime ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    return nowSeconds > expiryTimestampSeconds;
  }

  String encodeToQrPayload() {
    return '$enterpriseId:$employeeId:$issuedTimestampSeconds:$expiryTimestampSeconds:$signature';
  }

  static DigitalBadgeToken? decodeFromQrPayload(String payload) {
    try {
      final parts = payload.split(':');
      if (parts.length != 5) return null;
      return DigitalBadgeToken(
        enterpriseId: parts[0],
        employeeId: parts[1],
        issuedTimestampSeconds: int.parse(parts[2]),
        expiryTimestampSeconds: int.parse(parts[3]),
        signature: parts[4],
      );
    } catch (_) {
      return null;
    }
  }

  static String generateSignature({
    required String secretKey,
    required String enterpriseId,
    required String employeeId,
    required int issuedAt,
    required int expiresAt,
  }) {
    final message = '$enterpriseId|$employeeId|$issuedAt|$expiresAt';
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    return hmac.convert(utf8.encode(message)).toString();
  }
}
