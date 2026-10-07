import 'package:flutter/material.dart';
import '../services/shift_grace_period_rounding_service.dart';
import '../core/design_system/design_system.dart';

class ShiftGracePeriodRoundingCard extends StatelessWidget {
  final RoundedPunchResult result;
  final String label;

  const ShiftGracePeriodRoundingCard({
    super.key,
    required this.result,
    this.label = 'Attendance Punch',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isGrace = result.isGracePeriodApplied;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isGrace ? Colors.blue.shade300 : colors.outlineVariant,
          width: 1,
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
                  isGrace ? Icons.published_with_changes_rounded : Icons.schedule_rounded,
                  color: isGrace ? colors.primary : colors.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
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
                    color: (isGrace ? Colors.blue : Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isGrace ? 'GRACE FORGIVEN' : 'FLSA ROUNDED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isGrace ? colors.primary : colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Raw: ${_formatTime(result.rawTimestamp)} ➔ Rounded: ${_formatTime(result.roundedTimestamp)} (${result.differenceMinutes >= 0 ? "+" : ""}${result.differenceMinutes}m)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              isGrace
                  ? 'Arrival within 5-minute schedule window. Rounded to official shift start time without tardiness penalty.'
                  : 'Time calculated according to statutory 7/8 minute interval rounding schedule.',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
