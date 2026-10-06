import 'package:flutter/foundation.dart';

/// Virtual NFC Badge model for Host Card Emulation (HCE) to tap against biometric terminal readers
@immutable
class MobileVirtualNfcBadge {
  final String cardUid; // Emulated ISO 14443-A UID (7 bytes hex)
  final String employeeId;
  final String enterpriseId;
  final String applicationIdentifier; // e.g. AID 'F0010203040506'
  final String encryptedCardPayload;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isHceActive;

  const MobileVirtualNfcBadge({
    required this.cardUid,
    required this.employeeId,
    required this.enterpriseId,
    this.applicationIdentifier = 'F0010203040506',
    required this.encryptedCardPayload,
    required this.issuedAt,
    required this.expiresAt,
    this.isHceActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
        'cardUid': cardUid,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'applicationIdentifier': applicationIdentifier,
        'encryptedCardPayload': encryptedCardPayload,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isHceActive': isHceActive,
      };

  factory MobileVirtualNfcBadge.fromMap(Map<String, dynamic> map) =>
      MobileVirtualNfcBadge(
        cardUid: map['cardUid'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        applicationIdentifier: map['applicationIdentifier'] as String? ?? 'F0010203040506',
        encryptedCardPayload: map['encryptedCardPayload'] as String? ?? '',
        issuedAt: map['issuedAt'] != null
            ? DateTime.tryParse(map['issuedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: map['expiresAt'] != null
            ? DateTime.tryParse(map['expiresAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        isHceActive: map['isHceActive'] as bool? ?? true,
      );
}
