import 'package:flutter/material.dart';
import '../services/per_diem_allowance_service.dart';
import '../core/design_system/design_system.dart';

class PerDiemAllowanceCard extends StatelessWidget {
  final PerDiemDisbursementRecord record;

  const PerDiemAllowanceCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasAllowance = record.totalAllowance > 0;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasAllowance ? Colors.teal.shade300 : colors.outlineVariant,
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
                  hasAllowance ? Icons.lunch_dining_rounded : Icons.money_off_rounded,
                  color: hasAllowance ? Colors.teal.shade700 : colors.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.employeeName,
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
                    color: (hasAllowance ? Colors.teal : Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${record.currencyCode} ${record.totalAllowance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasAllowance ? Colors.teal.shade800 : colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${record.workedHours.toStringAsFixed(1)} hrs • ${record.isNightShift ? "Night Shift" : "Day Shift"} • ${record.shiftDate.year}-${record.shiftDate.month.toString().padLeft(2, '0')}-${record.shiftDate.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (record.qualificationReasons.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                record.qualificationReasons.join(' • '),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
