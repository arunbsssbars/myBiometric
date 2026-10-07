import 'package:flutter/material.dart';
import '../services/visitor_badge_governor_service.dart';
import '../core/design_system/design_system.dart';

class VisitorBadgeGovernorCard extends StatelessWidget {
  final VisitorAccessBadge badge;
  final VoidCallback? onRevoke;

  const VisitorBadgeGovernorCard({
    super.key,
    required this.badge,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final effectiveStatus = badge.getEffectiveStatus(now);

    final isExpired = effectiveStatus != BadgeStatus.active;
    final badgeColor = effectiveStatus == BadgeStatus.active
        ? Colors.indigo
        : effectiveStatus == BadgeStatus.expired
            ? Colors.orange
            : colors.error;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: badgeColor.withValues(alpha: 0.4),
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
                  Icons.badge_rounded,
                  color: badgeColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    badge.visitorName,
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
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    effectiveStatus.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${badge.companyName} • Host: ${badge.hostEmployeeName} • ${badge.visitorType.name.toUpperCase()}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Expires: ${badge.expiresAt.hour.toString().padLeft(2, '0')}:${badge.expiresAt.minute.toString().padLeft(2, '0')} • PIN: ${badge.temporaryPin}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isExpired && onRevoke != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: colors.error),
                      onPressed: onRevoke,
                      child: const Text('Revoke', style: TextStyle(fontSize: 12)),
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
