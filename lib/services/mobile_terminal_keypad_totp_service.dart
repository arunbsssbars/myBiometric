import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/mobile_terminal_keypad_totp.dart';

/// Service generating and validating dynamic 6-digit PINs punched on terminal physical keypads
class MobileTerminalKeypadTotpService {
  /// Generates expiring 6-digit numeric TOTP code for employee
  MobileTerminalKeypadTotp generateKeypadPin({
    required String employeeId,
    required String enterpriseId,
    String? secretKey,
    int stepSeconds = 60,
  }) {
    final now = DateTime.now();
    final timeStep = now.millisecondsSinceEpoch ~/ (stepSeconds * 1000);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch((timeStep + 1) * stepSeconds * 1000);

    final key = utf8.encode(secretKey ?? 'ENTERPRISE_KEYPAD_HMAC_SECRET');
    final message = utf8.encode('$employeeId:$enterpriseId:$timeStep');
    final digest = Hmac(sha256, key).convert(message).bytes;

    // Standard dynamic truncation to extract 6 decimal digits
    final offset = digest.last & 0x0f;
    final binary = ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);

    final pin = (binary % 1000000).toString().padLeft(6, '0');

    return MobileTerminalKeypadTotp(
      pinCode: pin,
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      issuedAt: now,
      expiresAt: expiresAt,
      stepSeconds: stepSeconds,
    );
  }

  /// Verifies a 6-digit PIN entered on the physical terminal
  bool verifyKeypadPin({
    required String enteredPin,
    required String employeeId,
    required String enterpriseId,
    String? secretKey,
    int stepSeconds = 60,
  }) {
    final now = DateTime.now();
    final currentTimeStep = now.millisecondsSinceEpoch ~/ (stepSeconds * 1000);
    final key = utf8.encode(secretKey ?? 'ENTERPRISE_KEYPAD_HMAC_SECRET');

    // Check current step and previous step (allow 1 step grace for slow typing)
    for (int delta = -1; delta <= 0; delta++) {
      final step = currentTimeStep + delta;
      final message = utf8.encode('$employeeId:$enterpriseId:$step');
      final digest = Hmac(sha256, key).convert(message).bytes;

      final offset = digest.last & 0x0f;
      final binary = ((digest[offset] & 0x7f) << 24) |
          ((digest[offset + 1] & 0xff) << 16) |
          ((digest[offset + 2] & 0xff) << 8) |
          (digest[offset + 3] & 0xff);

      final expectedPin = (binary % 1000000).toString().padLeft(6, '0');
      if (expectedPin == enteredPin) {
        return true;
      }
    }

    return false;
  }
}
