import 'package:flutter/foundation.dart';

/// Cryptographic near-ultrasonic chirp payload for contactless acoustic machine pairing
@immutable
class UltrasonicPunchChirp {
  final String chirpId;
  final String employeeId;
  final String enterpriseId;
  final double carrierFrequencyHz; // e.g., 18500 Hz (near ultrasonic)
  final int durationMs;
  final String encryptedTonePayload;
  final DateTime issuedAt;

  const UltrasonicPunchChirp({
    required this.chirpId,
    required this.employeeId,
    required this.enterpriseId,
    this.carrierFrequencyHz = 18500.0,
    this.durationMs = 800,
    required this.encryptedTonePayload,
    required this.issuedAt,
  });

  Map<String, dynamic> toMap() => {
        'chirpId': chirpId,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'carrierFrequencyHz': carrierFrequencyHz,
        'durationMs': durationMs,
        'encryptedTonePayload': encryptedTonePayload,
        'issuedAt': issuedAt.toIso8601String(),
      };

  factory UltrasonicPunchChirp.fromMap(Map<String, dynamic> map) =>
      UltrasonicPunchChirp(
        chirpId: map['chirpId'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        carrierFrequencyHz: (map['carrierFrequencyHz'] as num?)?.toDouble() ?? 18500.0,
        durationMs: map['durationMs'] as int? ?? 800,
        encryptedTonePayload: map['encryptedTonePayload'] as String? ?? '',
        issuedAt: map['issuedAt'] != null
            ? DateTime.tryParse(map['issuedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
