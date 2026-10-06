import 'package:flutter/foundation.dart';

/// One-time time-based passcode (TOTP) model for punching on physical machine keypad
@immutable
class MobileTerminalKeypadTotp {
  final String pinCode; // 6-digit PIN
  final String employeeId;
  final String enterpriseId;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final int stepSeconds;

  const MobileTerminalKeypadTotp({
    required this.pinCode,
    required this.employeeId,
    required this.enterpriseId,
    required this.issuedAt,
    required this.expiresAt,
    this.stepSeconds = 60,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get remainingSeconds =>
      expiresAt.difference(DateTime.now()).inSeconds.clamp(0, stepSeconds);

  Map<String, dynamic> toMap() => {
        'pinCode': pinCode,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'stepSeconds': stepSeconds,
      };

  factory MobileTerminalKeypadTotp.fromMap(Map<String, dynamic> map) =>
      MobileTerminalKeypadTotp(
        pinCode: map['pinCode'] as String? ?? '000000',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        issuedAt: map['issuedAt'] != null
            ? DateTime.tryParse(map['issuedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: map['expiresAt'] != null
            ? DateTime.tryParse(map['expiresAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        stepSeconds: map['stepSeconds'] as int? ?? 60,
      );
}
