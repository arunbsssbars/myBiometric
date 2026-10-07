import 'package:flutter/material.dart';
import '../services/incident_root_cause_diagnosis_service.dart';
import '../core/design_system/design_system.dart';

class IncidentRootCauseDiagnosisCard extends StatelessWidget {
  final DiagnosticFinding finding;

  const IncidentRootCauseDiagnosisCard({
    super.key,
    required this.finding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isNetwork = finding.category == IncidentCategory.networkPartition;
    final isSensor = finding.category == IncidentCategory.sensorDegradation;

    final badgeColor = isNetwork
        ? colors.error
        : isSensor
            ? Colors.orange
            : colors.primary;

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
                  Icons.psychology_alt_rounded,
                  color: badgeColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    finding.rootCauseTitle,
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
                    '${(finding.confidenceScore * 100).toInt()}% CONFIDENCE',
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
              'Device: ${finding.deviceId} • Category: ${finding.category.name.toUpperCase()}',
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
              finding.explanation,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (finding.remediationSteps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Remediation: ${finding.remediationSteps.first}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
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
