import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/device_mtls_certificate.dart';
import 'package:mybiometric_app/services/device_certificate_service.dart';

void main() {
  group('DeviceCertificateService Suite', () {
    const deviceId = 'term_gate_01';
    const enterpriseId = 'ent_corp';

    test('Evaluates certificate validity and expiring soon window', () {
      final now = DateTime.now();

      final validCert = DeviceMtlsCertificate(
        certificateId: 'cert_1',
        deviceId: deviceId,
        enterpriseId: enterpriseId,
        commonName: 'term-gate-01.ent-corp.internal',
        issuer: 'Enterprise Root CA',
        certFingerprintSha256: 'sha256_dummy_hash_01',
        issuedAt: now.subtract(const Duration(days: 30)),
        expiresAt: now.add(const Duration(days: 300)),
        status: DeviceCertificateStatus.valid,
        isHardwareKeyBacked: true,
      );

      expect(validCert.isValid, isTrue);
      expect(DeviceCertificateService.instance.evaluateStatus(validCert), equals(DeviceCertificateStatus.valid));

      final expiringCert = validCert.copyWith(
        expiresAt: now.add(const Duration(days: 15)),
      );
      expect(DeviceCertificateService.instance.evaluateStatus(expiringCert), equals(DeviceCertificateStatus.expiringSoon));

      final expiredCert = validCert.copyWith(
        expiresAt: now.subtract(const Duration(days: 2)),
      );
      expect(DeviceCertificateService.instance.evaluateStatus(expiredCert), equals(DeviceCertificateStatus.expired));
    });

    test('Rolls and rotates certificate with updated fingerprint and expiry', () {
      final cert = DeviceMtlsCertificate(
        certificateId: 'cert_old',
        deviceId: deviceId,
        enterpriseId: enterpriseId,
        commonName: 'term-gate-01.ent-corp.internal',
        issuer: 'Enterprise Root CA',
        certFingerprintSha256: 'sha256_old',
        issuedAt: DateTime.now().subtract(const Duration(days: 360)),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        status: DeviceCertificateStatus.valid,
        isHardwareKeyBacked: true,
      );

      final rolled = DeviceCertificateService.instance.rollCertificate(
        currentCert: cert,
        validityDays: 180,
      );

      expect(rolled.certificateId, isNot(equals(cert.certificateId)));
      expect(rolled.certFingerprintSha256, isNot(equals(cert.certFingerprintSha256)));
      expect(rolled.status, equals(DeviceCertificateStatus.valid));
      expect(rolled.daysUntilExpiration, greaterThanOrEqualTo(179));
    });
  });
}
