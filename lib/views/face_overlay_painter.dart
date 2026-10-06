import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../core/design_system/app_palette.dart';

class FaceHolePainter extends CustomPainter {
  final Color? borderColor;
  final double borderWidth;
  final double progress; // 0.0 to 1.0

  FaceHolePainter({this.borderColor, this.borderWidth = 4.0, this.progress = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. Draw the dark overlay
    final paint = Paint()..color = AppPalette.slate900.withValues(alpha: 0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 2. Clear out the oval
    final center = Offset(size.width / 2, size.height / 2.5); // Slightly above center
    final ovalRect = Rect.fromCenter(center: center, width: 250, height: 350);
    
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..color = Colors.transparent;
    canvas.drawOval(ovalRect, clearPaint);

    canvas.restore(); // Composite back onto the camera preview

    // 3. Draw faint background border
    final bgBorderPaint = Paint()
      ..color = AppPalette.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawOval(ovalRect, bgBorderPaint);

    // 4. Draw progress arc
    if (progress > 0) {
      final effectiveBorderColor = borderColor ?? AppPalette.white;
      final progressPaint = Paint()
        ..color = effectiveBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 2.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
      
      canvas.drawArc(
        ovalRect,
        -math.pi / 2, // Start at top
        2 * math.pi * progress, // Sweep angle
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FaceHolePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor || 
           oldDelegate.borderWidth != borderWidth || 
           oldDelegate.progress != progress;
  }
}
