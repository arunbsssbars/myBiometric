import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/device_mtls_certificate.dart';

/// Service managing zero-trust client mTLS certificates, rotation, and revocation
class DeviceCertificateService {
  DeviceCertificateService._internal();
  static final DeviceCertificateService instance = DeviceCertificateService._internal();

  /// Computes deterministic certificate SHA-256 fingerprint from DER bytes or raw PEM
  static String computeCertFingerprint(String pemOrDerString) {
    return sha256.convert(utf8.encode(pemOrDerString)).toString();
  }

  /// Evaluates whether certificate is approaching renewal window (<= 30 days)
  DeviceCertificateStatus evaluateStatus(DeviceMtlsCertificate cert) {
    final now = DateTime.now();
    if (cert.status == DeviceCertificateStatus.revoked) {
      return DeviceCertificateStatus.revoked;
    }
    if (now.isAfter(cert.expiresAt)) {
      return DeviceCertificateStatus.expired;
    }
    if (cert.daysUntilExpiration <= 30) {
      return DeviceCertificateStatus.expiringSoon;
    }
    return DeviceCertificateStatus.valid;
  }

  /// Issues or rolls an updated certificate for a terminal
  DeviceMtlsCertificate rollCertificate({
    required DeviceMtlsCertificate currentCert,
    int validityDays = 365,
  }) {
    final now = DateTime.now();
    final newExpiry = now.add(Duration(days: validityDays));
    final newId = 'cert_${now.millisecondsSinceEpoch}';
    final newFp = computeCertFingerprint('${currentCert.deviceId}:$newId:${currentCert.enterpriseId}');

    return DeviceMtlsCertificate(
      certificateId: newId,
      deviceId: currentCert.deviceId,
      enterpriseId: currentCert.enterpriseId,
      commonName: currentCert.commonName,
      issuer: currentCert.issuer,
      certFingerprintSha256: newFp,
      issuedAt: now,
      expiresAt: newExpiry,
      status: DeviceCertificateStatus.valid,
      isHardwareKeyBacked: currentCert.isHardwareKeyBacked,
    );
  }
}
