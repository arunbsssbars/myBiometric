import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/device_mtls_certificate.dart';

/// Card presenting terminal zero-trust mTLS identity certificate details and validity window
class DeviceCertificateCard extends StatelessWidget {
  final DeviceMtlsCertificate certificate;
  final VoidCallback? onRotateCertificate;

  const DeviceCertificateCard({
    super.key,
    required this.certificate,
    this.onRotateCertificate,
  });

  Color _getStatusColor(BuildContext context, DeviceCertificateStatus status) {
    switch (status) {
      case DeviceCertificateStatus.valid:
        return context.status.success.color;
      case DeviceCertificateStatus.expiringSoon:
        return context.status.warning.color;
      case DeviceCertificateStatus.expired:
      case DeviceCertificateStatus.revoked:
        return context.status.danger.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, certificate.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: certificate.status == DeviceCertificateStatus.expired
              ? context.status.danger.color.withValues(alpha: 0.3)
              : context.colors.borderSubtle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  certificate.isHardwareKeyBacked
                      ? Icons.verified_user_rounded
                      : Icons.lock_outline_rounded,
                  size: 22,
                  color: statusColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.commonName,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Issuer: ${certificate.issuer}',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    certificate.status.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hardware Keystore', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        certificate.isHardwareKeyBacked ? 'Secure Enclave' : 'Software Keystore',
                        style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expires In', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${certificate.daysUntilExpiration} days',
                        style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'SHA-256: ${certificate.certFingerprintSha256.substring(0, 16)}...',
                    style: context.text.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onRotateCertificate != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onRotateCertificate,
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Rotate'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
