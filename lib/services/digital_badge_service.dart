import '../domain/models/digital_badge_token.dart';

/// Service generating and validating dynamic cryptographically signed digital badges
class DigitalBadgeService {
  /// Generates a fresh dynamic QR badge with a short TTL (e.g. 60 seconds)
  static DigitalBadgeToken generateBadge({
    required String enterpriseId,
    required String employeeId,
    required String secretKey,
    Duration validity = const Duration(minutes: 5),
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final issuedSec = current.millisecondsSinceEpoch ~/ 1000;
    final expirySec = current.add(validity).millisecondsSinceEpoch ~/ 1000;

    final sig = DigitalBadgeToken.generateSignature(
      secretKey: secretKey,
      enterpriseId: enterpriseId,
      employeeId: employeeId,
      issuedAt: issuedSec,
      expiresAt: expirySec,
    );

    return DigitalBadgeToken(
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      issuedTimestampSeconds: issuedSec,
      expiryTimestampSeconds: expirySec,
      signature: sig,
    );
  }

  /// Validates an incoming badge payload scanned at the kiosk terminal
  static bool validateScannedBadge({
    required String qrPayload,
    required String secretKey,
    required String expectedEnterpriseId,
    DateTime? verificationTime,
  }) {
    final token = DigitalBadgeToken.decodeFromQrPayload(qrPayload);
    if (token == null) return false;

    if (token.enterpriseId != expectedEnterpriseId) return false;
    if (token.isExpired(currentTime: verificationTime)) return false;

    final expectedSig = DigitalBadgeToken.generateSignature(
      secretKey: secretKey,
      enterpriseId: token.enterpriseId,
      employeeId: token.employeeId,
      issuedAt: token.issuedTimestampSeconds,
      expiresAt: token.expiryTimestampSeconds,
    );

    return token.signature == expectedSig;
  }
}
