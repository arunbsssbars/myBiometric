import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/security_telemetry_incident.dart';

/// Card presenting security telemetry incidents, threat severity, and SIEM status
class SecurityTelemetryCard extends StatelessWidget {
  final SecurityTelemetryIncident incident;
  final VoidCallback? onAcknowledge;

  const SecurityTelemetryCard({
    super.key,
    required this.incident,
    this.onAcknowledge,
  });

  Color _getSeverityColor(BuildContext context, IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return context.status.neutral.color;
      case IncidentSeverity.medium:
        return context.status.warning.color;
      case IncidentSeverity.high:
      case IncidentSeverity.critical:
        return context.status.danger.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(context, incident.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: incident.severity == IncidentSeverity.critical
              ? context.status.danger.color.withValues(alpha: 0.3)
              : context.colors.borderSubtle,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 22, color: severityColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    incident.incidentType,
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
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    incident.severity.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              incident.description,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ${incident.status.name.toUpperCase()}',
                  style: context.text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textSecondary,
                  ),
                ),
                if (onAcknowledge != null && incident.isActionRequired)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onAcknowledge,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Resolve'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
