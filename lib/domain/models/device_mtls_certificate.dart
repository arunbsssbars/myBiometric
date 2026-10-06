import 'package:flutter/foundation.dart';

enum DeviceCertificateStatus {
  valid,
  expiringSoon,
  expired,
  revoked,
}

/// X.509 device identity certificate metadata for zero-trust terminal mutual TLS
@immutable
class DeviceMtlsCertificate {
  final String certificateId;
  final String deviceId;
  final String enterpriseId;
  final String commonName;
  final String issuer;
  final String certFingerprintSha256;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DeviceCertificateStatus status;
  final bool isHardwareKeyBacked; // Secure Enclave or Android StrongBox / KeyStore

  const DeviceMtlsCertificate({
    required this.certificateId,
    required this.deviceId,
    required this.enterpriseId,
    required this.commonName,
    required this.issuer,
    required this.certFingerprintSha256,
    required this.issuedAt,
    required this.expiresAt,
    required this.status,
    this.isHardwareKeyBacked = true,
  });

  bool get isValid =>
      status == DeviceCertificateStatus.valid &&
      DateTime.now().isBefore(expiresAt);

  int get daysUntilExpiration =>
      expiresAt.difference(DateTime.now()).inDays;

  DeviceMtlsCertificate copyWith({
    String? certificateId,
    String? deviceId,
    String? enterpriseId,
    String? commonName,
    String? issuer,
    String? certFingerprintSha256,
    DateTime? issuedAt,
    DateTime? expiresAt,
    DeviceCertificateStatus? status,
    bool? isHardwareKeyBacked,
  }) {
    return DeviceMtlsCertificate(
      certificateId: certificateId ?? this.certificateId,
      deviceId: deviceId ?? this.deviceId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      commonName: commonName ?? this.commonName,
      issuer: issuer ?? this.issuer,
      certFingerprintSha256: certFingerprintSha256 ?? this.certFingerprintSha256,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      isHardwareKeyBacked: isHardwareKeyBacked ?? this.isHardwareKeyBacked,
    );
  }

  Map<String, dynamic> toMap() => {
        'certificateId': certificateId,
        'deviceId': deviceId,
        'enterpriseId': enterpriseId,
        'commonName': commonName,
        'issuer': issuer,
        'certFingerprintSha256': certFingerprintSha256,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': status.name,
        'isHardwareKeyBacked': isHardwareKeyBacked,
      };

  factory DeviceMtlsCertificate.fromMap(Map<String, dynamic> map) =>
      DeviceMtlsCertificate(
        certificateId: map['certificateId'] as String? ?? '',
        deviceId: map['deviceId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        commonName: map['commonName'] as String? ?? '',
        issuer: map['issuer'] as String? ?? 'Enterprise Internal CA',
        certFingerprintSha256: map['certFingerprintSha256'] as String? ?? '',
        issuedAt: map['issuedAt'] != null
            ? DateTime.tryParse(map['issuedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        expiresAt: map['expiresAt'] != null
            ? DateTime.tryParse(map['expiresAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        status: DeviceCertificateStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => DeviceCertificateStatus.valid,
        ),
        isHardwareKeyBacked: map['isHardwareKeyBacked'] as bool? ?? true,
      );
}
