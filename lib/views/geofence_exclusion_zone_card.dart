import 'package:flutter/material.dart';
import '../services/geofence_exclusion_zone_service.dart';
import '../core/design_system/design_system.dart';

class GeofenceExclusionZoneCard extends StatelessWidget {
  final ExclusionPolygonZone zone;
  final int violationCount;
  final VoidCallback? onToggleActive;

  const GeofenceExclusionZoneCard({
    super.key,
    required this.zone,
    this.violationCount = 0,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isActive = zone.isActive;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.red.shade300 : colors.outlineVariant,
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
                  Icons.not_listed_location_rounded,
                  color: isActive ? Colors.red.shade700 : colors.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.name,
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
                    color: (isActive ? Colors.red : Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'RESTRICTED' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.red.shade700 : colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              zone.reason,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${zone.vertices.length} Vertices • Violations: $violationCount • Branch: ${zone.branchId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onToggleActive != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                    child: IconButton(
                      icon: Icon(
                        isActive ? Icons.toggle_on : Icons.toggle_off,
                        color: isActive ? Colors.red.shade700 : colors.onSurfaceVariant,
                        size: 28,
                      ),
                      onPressed: onToggleActive,
                      tooltip: isActive ? 'Deactivate Zone' : 'Activate Zone',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
