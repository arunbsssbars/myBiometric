import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/multi_format_payroll_export.dart';

/// Responsive Material 3 card allowing administrators to export attendance into ERP formats
/// (SAP CAT2, ADP, Workday, Tally). Built strictly following AQIL v2 responsive standards.
class MultiFormatPayrollExportCard extends StatelessWidget {
  final PayrollExportConfig config;
  final PayrollExportResult? latestExport;
  final VoidCallback? onTriggerExport;

  const MultiFormatPayrollExportCard({
    super.key,
    required this.config,
    this.latestExport,
    this.onTriggerExport,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);

    final formatLabel = _getFormatLabel(config.format);

    final metaItems = <String>[
      'Format: $formatLabel',
      'CoCode: ${config.companyCode}',
      if (latestExport != null) '${latestExport!.totalRecords} records in batch',
    ];
    final metaString = metaItems.join(' • ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: context.colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: context.colors.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: context.colors.primary,
                    size: AppSizes.iconMd,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enterprise Payroll Export Hub',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        metaString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.status.success.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    config.format.name.toUpperCase(),
                    style: context.textStyles.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.status.success.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (latestExport != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: context.colors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: context.colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        latestExport!.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${latestExport!.totalRegularHours.toStringAsFixed(0)}h Reg • ${latestExport!.totalOvertimeHours.toStringAsFixed(0)}h OT',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onTriggerExport != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(AppSizes.minTouchTarget, 36),
                  ),
                  onPressed: onTriggerExport,
                  icon: const Icon(Icons.file_download_outlined, size: 14),
                  label: const Text('Generate Interchange Export'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _getFormatLabel(PayrollExportFormat format) {
    switch (format) {
      case PayrollExportFormat.sapCat2:
        return 'SAP CAT2 Timesheet';
      case PayrollExportFormat.adpCsv:
        return 'ADP Enterprise eTime';
      case PayrollExportFormat.workdayXml:
        return 'Workday XML';
      case PayrollExportFormat.tallyXml:
        return 'Tally ERP XML';
      case PayrollExportFormat.standardCsv:
        return 'Standard CSV';
    }
  }
}
