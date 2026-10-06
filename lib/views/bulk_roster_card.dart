import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/bulk_roster_import.dart';

/// AQIL-hardened summary bar for bulk roster import parsing results.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class BulkRosterSummaryBar extends StatelessWidget {
  final BulkImportResult result;

  const BulkRosterSummaryBar({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusTheme = context.status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildSummaryItem(context, 'Total Rows', '${result.totalRows}', colors.primary)),
          Container(width: 1, height: 28, color: colors.outlineVariant.withValues(alpha: 0.3)),
          Expanded(child: _buildSummaryItem(context, 'Valid', '${result.validCount}', statusTheme.success.color)),
          Container(width: 1, height: 28, color: colors.outlineVariant.withValues(alpha: 0.3)),
          Expanded(child: _buildSummaryItem(context, 'Errors', '${result.invalidCount}', statusTheme.danger.color)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    final textTheme = context.text;
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// AQIL-hardened card for previewing parsed bulk import records.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class BulkRosterRecordCard extends StatelessWidget {
  final BulkImportRecord record;

  const BulkRosterRecordCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    final isValid = record.isValid;
    final cardColor = isValid ? colors.surfaceContainerLowest : statusTheme.danger.container;
    final borderColor = isValid
        ? colors.outlineVariant.withValues(alpha: 0.5)
        : statusTheme.danger.color.withValues(alpha: 0.3);

    final metadataParts = <String>[
      record.role.toUpperCase(),
      if (record.department.isNotEmpty) record.department,
      if (record.branchId.isNotEmpty) record.branchId,
      if (record.assignedShift.isNotEmpty) record.assignedShift,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: isValid ? statusTheme.success.color : statusTheme.danger.color,
                  size: AppSizes.iconSm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Row ${record.rowNumber}: ${record.fullName.isEmpty ? "[No Name]" : record.fullName}',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    record.employeeId.isEmpty ? 'NO ID' : record.employeeId,
                    style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              metadataParts.join(' • '),
              style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isValid) ...[
              const SizedBox(height: AppSpacing.sm),
              ...record.errors.map(
                (err) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right_rounded, size: AppSizes.iconSm, color: statusTheme.danger.color),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          err,
                          style: textTheme.bodySmall?.copyWith(
                            color: statusTheme.danger.color,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
