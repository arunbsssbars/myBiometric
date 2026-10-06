import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/ultrasonic_punch_chirp.dart';

/// Service synthesizing acoustic FSK tokens emitted by phone speaker to machine microphone
class UltrasonicPunchChirpService {
  /// Generates acoustic tone chirp token
  UltrasonicPunchChirp generateChirp({
    required String employeeId,
    required String enterpriseId,
    String? secretKey,
  }) {
    final now = DateTime.now();
    final key = utf8.encode(secretKey ?? 'ENTERPRISE_ACOUSTIC_CHIRP_SECRET');
    final raw = utf8.encode('$employeeId:$enterpriseId:${now.millisecondsSinceEpoch ~/ 15000}');
    final sig = Hmac(sha256, key).convert(raw).toString().substring(0, 12);

    return UltrasonicPunchChirp(
      chirpId: 'CHIRP_${now.millisecondsSinceEpoch}',
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      carrierFrequencyHz: 18500.0,
      durationMs: 750,
      encryptedTonePayload: sig,
      issuedAt: now,
    );
  }

  /// Verifies detected audio chirp token captured by machine microphone
  bool verifyAudioChirp(UltrasonicPunchChirp chirp, {String? secretKey}) {
    final now = DateTime.now();
    final diffSeconds = now.difference(chirp.issuedAt).inSeconds.abs();
    if (diffSeconds > 60) return false;

    final key = utf8.encode(secretKey ?? 'ENTERPRISE_ACOUSTIC_CHIRP_SECRET');
    final timeStep = chirp.issuedAt.millisecondsSinceEpoch ~/ 15000;

    for (int delta = -1; delta <= 1; delta++) {
      final raw = utf8.encode('${chirp.employeeId}:${chirp.enterpriseId}:${timeStep + delta}');
      final sig = Hmac(sha256, key).convert(raw).toString().substring(0, 12);
      if (sig == chirp.encryptedTonePayload) {
        return true;
      }
    }

    return false;
  }
}
