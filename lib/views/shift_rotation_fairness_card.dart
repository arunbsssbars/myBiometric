import 'package:flutter/material.dart';
import '../services/shift_rotation_fairness_service.dart';
import '../core/design_system/design_system.dart';

class ShiftRotationFairnessCard extends StatelessWidget {
  final ShiftEquityScore score;

  const ShiftRotationFairnessCard({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isFatigued = score.hasFatigueWarning;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFatigued ? colors.error : colors.outlineVariant,
          width: isFatigued ? 1.5 : 1.0,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isFatigued ? Icons.bedtime_off_rounded : Icons.nights_stay_rounded,
                  color: isFatigued ? colors.error : colors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    score.employeeName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isFatigued ? colors.error : Colors.green).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isFatigued ? 'FATIGUE RISK' : 'BALANCED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isFatigued ? colors.error : Colors.green.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fatigue Index: ${score.fatigueRiskScore.toStringAsFixed(1)} / 100',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Nights: ${score.nightLoadPercentage.toStringAsFixed(0)}% • Wknds: ${score.weekendLoadPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (score.fatigueRiskScore / 100).clamp(0.0, 1.0),
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFatigued ? colors.error : colors.primary,
              ),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}
