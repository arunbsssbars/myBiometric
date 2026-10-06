import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/mobile_optical_qr_punch_token.dart';
import '../../services/mobile_optical_qr_punch_service.dart';

/// Card displaying the mobile dynamic QR badge for hands-free presentation before the biometric machine
class MobileOpticalQrPunchCard extends StatelessWidget {
  final MobileOpticalQrPunchToken token;
  final VoidCallback? onRefresh;

  const MobileOpticalQrPunchCard({
    super.key,
    required this.token,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = token.remainingSeconds;
    final isExpired = token.isExpired;
    final payload = MobileOpticalQrPunchService.instance.formatQrCodePayload(token);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isExpired
              ? context.status.danger.color.withValues(alpha: 0.3)
              : context.colors.borderSubtle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2_rounded, size: 24, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Machine Optical Punch QR',
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isExpired ? context.status.danger.color : context.status.success.color)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    isExpired ? 'EXPIRED' : '${remaining}s LEFT',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isExpired ? context.status.danger.color : context.status.success.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              height: 150,
              width: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: context.colors.borderSubtle),
              ),
              child: Center(
                child: isExpired
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded,
                              size: 40, color: context.status.danger.color),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Refresh'),
                            onPressed: onRefresh,
                          ),
                        ],
                      )
                    : CustomPaint(
                        size: const Size(130, 130),
                        painter: _QrMatrixPainter(payload: payload),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Present this QR in front of the Hikvision MinMoe or ZKTeco optical reader to punch ${token.punchType.replaceAll('_', ' ')}',
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final String payload;
  final QrImage qrImage;

  _QrMatrixPainter({required this.payload})
      : qrImage = _generateQr(payload);

  static QrImage _generateQr(String data) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    return QrImage(qrCode);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final moduleCount = qrImage.moduleCount;
    final pixelSize = size.width / moduleCount;

    for (int x = 0; x < moduleCount; x++) {
      for (int y = 0; y < moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) =>
      oldDelegate.payload != payload;
}
