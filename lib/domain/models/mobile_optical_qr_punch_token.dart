import 'package:flutter/foundation.dart';

/// Dynamic QR token payload rendered on employee mobile screen to present before MinMoe camera
@immutable
class MobileOpticalQrPunchToken {
  final String tokenId;
  final String employeeId;
  final String enterpriseId;
  final String punchType; // 'PUNCH_IN' or 'PUNCH_OUT'
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String totpSignature;
  final String? boundDeviceId;

  const MobileOpticalQrPunchToken({
    required this.tokenId,
    required this.employeeId,
    required this.enterpriseId,
    required this.punchType,
    required this.issuedAt,
    required this.expiresAt,
    required this.totpSignature,
    this.boundDeviceId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get remainingSeconds =>
      expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 300);

  Map<String, dynamic> toMap() => {
        'tokenId': tokenId,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'punchType': punchType,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'totpSignature': totpSignature,
        'boundDeviceId': boundDeviceId,
      };

  factory MobileOpticalQrPunchToken.fromMap(Map<String, dynamic> map) =>
      MobileOpticalQrPunchToken(
        tokenId: map['tokenId'] as String? ?? '',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        punchType: map['punchType'] as String? ?? 'PUNCH_IN',
        issuedAt: map['issuedAt'] != null
            ? DateTime.tryParse(map['issuedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: map['expiresAt'] != null
            ? DateTime.tryParse(map['expiresAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        totpSignature: map['totpSignature'] as String? ?? '',
        boundDeviceId: map['boundDeviceId'] as String?,
      );
}
