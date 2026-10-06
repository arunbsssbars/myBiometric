import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_diagnostic_report.dart';
import '../services/terminal_health_diagnostic_service.dart';

/// Responsive modal bottom sheet presenting live hardware diagnostics,
/// latency metrics, firmware details, and memory utilization for an external biometric machine.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalDiagnosticSheet extends StatefulWidget {
  final BiometricTerminalDevice device;
  final String enterpriseId;
  final TerminalDiagnosticReport? initialReport;
  final VoidCallback? onProbed;

  const TerminalDiagnosticSheet({
    super.key,
    required this.device,
    required this.enterpriseId,
    this.initialReport,
    this.onProbed,
  });

  @override
  State<TerminalDiagnosticSheet> createState() => _TerminalDiagnosticSheetState();
}

class _TerminalDiagnosticSheetState extends State<TerminalDiagnosticSheet> {
  late TerminalHealthDiagnosticService _diagnosticService;
  TerminalDiagnosticReport? _report;
  bool _isProbing = false;

  @override
  void initState() {
    super.initState();
    _diagnosticService = TerminalHealthDiagnosticService();
    _report = widget.initialReport;
    if (_report == null) {
      _runProbe();
    }
  }

  Future<void> _runProbe() async {
    setState(() => _isProbing = true);
    try {
      final res = await _diagnosticService.probeDevice(widget.device);
      await _diagnosticService.saveDiagnosticReport(widget.enterpriseId, res);
      if (mounted) {
        setState(() {
          _report = res;
          _isProbing = false;
        });
        widget.onProbed?.call();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProbing = false);
      }
    }
  }

  Color _getGradeColor(BuildContext context, TerminalHealthGrade grade) {
    final statusTheme = context.status;
    final colors = context.colors;
    switch (grade) {
      case TerminalHealthGrade.excellent:
        return statusTheme.success.color;
      case TerminalHealthGrade.good:
        return statusTheme.info.color;
      case TerminalHealthGrade.warning:
        return statusTheme.warning.color;
      case TerminalHealthGrade.critical:
        return statusTheme.danger.color;
      case TerminalHealthGrade.offline:
        return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;
    final report = _report;

    final gradeColor = report != null
        ? _getGradeColor(context, report.healthGrade)
        : colors.primary;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),

              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.troubleshoot_rounded, color: colors.primary, size: AppSizes.iconMd),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.device.name,
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${widget.device.modelName} • ${widget.device.ipAddress}:${widget.device.port}',
                          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: AppSizes.iconSm, color: colors.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Health Score Gauge Card
              if (report != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: gradeColor,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxs),
                              child: Text(
                                '${report.healthScore}%',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colors.surfaceContainerLowest,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                  decoration: BoxDecoration(
                                    color: gradeColor,
                                    borderRadius: BorderRadius.circular(AppRadius.xs),
                                  ),
                                  child: Text(
                                    report.healthGradeLabel,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.surfaceContainerLowest,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    report.isReachable ? 'Hardware Online' : 'No Response',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: gradeColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              report.statusSummary,
                              style: textTheme.bodySmall?.copyWith(color: colors.onSurface),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Metrics Grid
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _buildMetricBox(
                      context,
                      icon: Icons.speed_rounded,
                      label: 'Network Latency',
                      value: report.isReachable ? '${report.latencyMs} ms' : 'Timeout',
                      color: report.latencyMs < 100 ? statusTheme.success.color : statusTheme.warning.color,
                    ),
                    _buildMetricBox(
                      context,
                      icon: Icons.storage_rounded,
                      label: 'Flash Storage',
                      value: report.isReachable ? '${report.storageUsagePercent.toStringAsFixed(1)}%' : 'N/A',
                      color: colors.primary,
                    ),
                    _buildMetricBox(
                      context,
                      icon: Icons.access_time_rounded,
                      label: 'NTP Time Drift',
                      value: report.isReachable ? '${report.timeDriftSeconds}s offset' : 'N/A',
                      color: report.timeDriftSeconds.abs() < 5 ? statusTheme.success.color : statusTheme.danger.color,
                    ),
                    _buildMetricBox(
                      context,
                      icon: Icons.system_update_alt_rounded,
                      label: 'Firmware OS',
                      value: report.firmwareVersion ?? 'Unknown',
                      color: statusTheme.info.color,
                    ),
                  ],
                ),
              ] else if (_isProbing) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 3, color: colors.primary),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Probing biometric terminal endpoint...',
                          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProbing ? null : _runProbe,
                      icon: _isProbing
                          ? SizedBox(
                              width: AppSizes.iconSm,
                              height: AppSizes.iconSm,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                            )
                          : const Icon(Icons.refresh_rounded, size: AppSizes.iconSm),
                      label: Text(
                        'Re-Probe Machine',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.surfaceContainerHighest,
                        foregroundColor: colors.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                      child: Text('Done', style: textTheme.labelLarge),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.colors;
    final textTheme = context.text;
    final width = (MediaQuery.sizeOf(context).width - 48 - 8) / 2;

    return Container(
      width: width.clamp(130.0, 300.0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconSm * 0.8, color: color),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
