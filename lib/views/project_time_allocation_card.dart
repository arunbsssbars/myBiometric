import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/work_project.dart';
import '../core/utils/app_format_utils.dart';

/// Responsive Material 3 card visualizing employee or enterprise time allocation across projects.
/// Built strictly following AQIL defensive responsive standards.
class ProjectTimeAllocationCard extends StatelessWidget {
  final ProjectAllocationSummary summary;
  final VoidCallback? onManageProjects;

  const ProjectTimeAllocationCard({
    super.key,
    required this.summary,
    this.onManageProjects,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Proportional horizontal padding
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    // Build subtitle safely using AQIL single-text join
    final metaItems = <String>[
      '${summary.allocations.length} projects tracked',
      '${summary.formattedTotalHours} total logged',
      '${summary.billableRatioPercent.toStringAsFixed(0)}% billable',
    ];
    final metaString = metaItems.join(' • ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.folder_shared_rounded, color: context.colors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Project & Client Allocation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        metaString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onManageProjects != null)
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: onManageProjects,
                    tooltip: 'Manage projects',
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Allocations List
            if (summary.allocations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No project-tagged time logs recorded.',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...summary.allocations.take(4).map((alloc) => _buildProjectRow(context, alloc)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectRow(BuildContext context, ProjectTimeAllocation alloc) {
    final theme = Theme.of(context);
    final color = AppFormatUtils.parseHexColor(alloc.project.colorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alloc.project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${alloc.formattedHours} (${alloc.percentageOfTotal.toStringAsFixed(0)}%)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (alloc.percentageOfTotal / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
