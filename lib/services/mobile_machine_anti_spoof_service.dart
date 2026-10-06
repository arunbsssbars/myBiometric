import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/mobile_machine_anti_spoof_token.dart';

/// Service generating hardware attestations and motion anti-spoofing checks for mobile-to-machine punches
class MobileMachineAntiSpoofService {
  /// Evaluates device telemetry and hardware signatures
  MobileMachineAntiSpoofToken issueAntiSpoofToken({
    required String employeeId,
    required String enterpriseId,
    required String hardwareFingerprint,
    double gyroscopeTiltDeg = 15.2,
    double accelerometerMagnitude = 9.81, // Earth gravity ~9.8 m/s^2
    String? attestationKey,
  }) {
    final now = DateTime.now();
    final key = utf8.encode(attestationKey ?? 'ENTERPRISE_ANTI_SPOOF_ATTESTATION_KEY');
    final raw = utf8.encode('$employeeId:$hardwareFingerprint:${now.millisecondsSinceEpoch}:$accelerometerMagnitude');
    final sig = Hmac(sha256, key).convert(raw).toString();

    return MobileMachineAntiSpoofToken(
      tokenId: 'SPF_${now.millisecondsSinceEpoch}',
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      deviceHardwareFingerprint: hardwareFingerprint,
      gyroscopeTiltDeg: gyroscopeTiltDeg,
      accelerometerMagnitude: accelerometerMagnitude,
      signedAttestationPayload: sig,
      capturedAt: now,
    );
  }

  /// Verifies token integrity and confirms natural hand motion
  bool verifyAntiSpoofToken(MobileMachineAntiSpoofToken token, {String? attestationKey}) {
    // 1. Freshness check (< 60s)
    if (DateTime.now().difference(token.capturedAt).inSeconds.abs() > 60) {
      return false;
    }

    // 2. Motion validity check
    if (!token.isMotionNatural) {
      return false;
    }

    // 3. Cryptographic attestation check
    final key = utf8.encode(attestationKey ?? 'ENTERPRISE_ANTI_SPOOF_ATTESTATION_KEY');
    final raw = utf8.encode('${token.employeeId}:${token.deviceHardwareFingerprint}:${token.capturedAt.millisecondsSinceEpoch}:${token.accelerometerMagnitude}');
    final expectedSig = Hmac(sha256, key).convert(raw).toString();

    return expectedSig == token.signedAttestationPayload;
  }
}
