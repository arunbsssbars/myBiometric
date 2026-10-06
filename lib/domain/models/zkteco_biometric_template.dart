import 'package:flutter/foundation.dart';

enum ZkFingerprintAlgVersion {
  zkFinger9,
  zkFinger10,
  zkFinger12,
}

/// ZKTeco biometric template registration payload (Fingerprint / Face template)
@immutable
class ZktecoBiometricTemplate {
  final String pin;
  final int fingerId; // 0 to 9
  final ZkFingerprintAlgVersion algorithm;
  final String templateBase64;
  final int templateSize;
  final int privilege; // 0 = Normal, 14 = Super Admin
  final String? password;
  final String? cardNo;

  const ZktecoBiometricTemplate({
    required this.pin,
    required this.fingerId,
    this.algorithm = ZkFingerprintAlgVersion.zkFinger10,
    required this.templateBase64,
    required this.templateSize,
    this.privilege = 0,
    this.password,
    this.cardNo,
  });

  Map<String, dynamic> toMap() => {
        'pin': pin,
        'fingerId': fingerId,
        'algorithm': algorithm.name,
        'templateBase64': templateBase64,
        'templateSize': templateSize,
        'privilege': privilege,
        'password': password,
        'cardNo': cardNo,
      };

  factory ZktecoBiometricTemplate.fromMap(Map<String, dynamic> map) =>
      ZktecoBiometricTemplate(
        pin: map['pin'] as String? ?? '',
        fingerId: (map['fingerId'] as num?)?.toInt() ?? 0,
        algorithm: ZkFingerprintAlgVersion.values.firstWhere(
          (e) => e.name == map['algorithm'],
          orElse: () => ZkFingerprintAlgVersion.zkFinger10,
        ),
        templateBase64: map['templateBase64'] as String? ?? '',
        templateSize: (map['templateSize'] as num?)?.toInt() ?? 0,
        privilege: (map['privilege'] as num?)?.toInt() ?? 0,
        password: map['password'] as String?,
        cardNo: map['cardNo'] as String?,
      );
}
