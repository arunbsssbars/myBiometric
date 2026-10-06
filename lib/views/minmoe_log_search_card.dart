import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/minmoe_log_search_query.dart';

/// Card presenting historical log search results from Hikvision MinMoe terminals
class MinMoeLogSearchCard extends StatelessWidget {
  final List<MinMoeSearchedRecord> records;
  final VoidCallback? onTriggerSearch;

  const MinMoeLogSearchCard({
    super.key,
    required this.records,
    this.onTriggerSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.manage_search_rounded, size: 22, color: context.colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'MinMoe Access Log Query',
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
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${records.length} RETRIEVED',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Direct ISAPI AcsEvent historical log pull with pagination and employee filter',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (records.isNotEmpty) ...[
              const Divider(height: 20),
              ...records.take(2).map((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Emp: ${rec.employeeNo}', style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${rec.timestamp.hour.toString().padLeft(2, '0')}:${rec.timestamp.minute.toString().padLeft(2, '0')}',
                            style: context.text.bodySmall?.copyWith(color: context.colors.textSecondary)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
