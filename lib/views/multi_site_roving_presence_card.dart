import 'package:flutter/material.dart';
import '../services/multi_site_roving_presence_service.dart';
import '../core/design_system/design_system.dart';

class MultiSiteRovingPresenceCard extends StatelessWidget {
  final EmployeeRovingDayRecord record;

  const MultiSiteRovingPresenceCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRoving = record.isMultiSiteRoving;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRoving ? Colors.purple.shade300 : colors.outlineVariant,
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
                  isRoving ? Icons.transfer_within_a_station_rounded : Icons.location_city_rounded,
                  color: isRoving ? Colors.purple.shade700 : colors.primary,
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
                    color: (isRoving ? Colors.purple : Colors.blue).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRoving ? 'MULTI-SITE ROVING' : 'SINGLE SITE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isRoving ? Colors.purple.shade800 : colors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${record.visitedBranchIds.length} Facilities Visited • ${record.transits.length} Transit Intervals',
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
              isRoving
                  ? 'Total In-Transit Duration: ${record.totalTransitDuration.inMinutes} mins'
                  : 'Stationary presence at single facility',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
