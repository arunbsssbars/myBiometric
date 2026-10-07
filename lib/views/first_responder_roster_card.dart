import 'package:flutter/material.dart';
import '../services/first_responder_roster_service.dart';
import '../core/design_system/design_system.dart';

class FirstResponderRosterCard extends StatelessWidget {
  final OnSiteFirstResponderSummary summary;

  const FirstResponderRosterCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasQuorum = summary.hasMinimumSafetyQuorum;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasQuorum ? Colors.green.shade300 : colors.error,
          width: hasQuorum ? 1.0 : 1.5,
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
                  hasQuorum ? Icons.medical_services_rounded : Icons.emergency_rounded,
                  color: hasQuorum ? Colors.green.shade700 : colors.error,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Emergency Safety Quorum',
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
                    color: (hasQuorum ? Colors.green : colors.error).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasQuorum ? 'SAFE QUORUM' : 'DEFICIT ALERT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasQuorum ? Colors.green.shade800 : colors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${summary.totalOnSiteResponders} Certified Staff Present • CPR: ${summary.cprCertifiedCount} • Fire Wardens: ${summary.fireWardenCount}',
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
              hasQuorum
                  ? 'Facility meets OSHA fire safety & CPR first-responder coverage requirements.'
                  : 'Warning: Under minimum safety threshold. At least 1 CPR and 1 Fire Warden required.',
              style: TextStyle(
                fontSize: 12,
                color: hasQuorum ? colors.onSurfaceVariant : colors.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
