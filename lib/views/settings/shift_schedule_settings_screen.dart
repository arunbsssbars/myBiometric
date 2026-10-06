import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/shift_schedule.dart';
import '../../services/database_service.dart';
import '../../core/network/network_connection_service.dart';
import '../../services/audit_log_service.dart';

/// Enterprise Work Shift & Policy Settings Screen.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class ShiftScheduleSettingsScreen extends StatefulWidget {
  final String enterpriseId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? enterpriseData;

  const ShiftScheduleSettingsScreen({
    super.key,
    required this.enterpriseId,
    this.initialData,
    this.enterpriseData,
  });

  @override
  State<ShiftScheduleSettingsScreen> createState() => _ShiftScheduleSettingsScreenState();
}

class _ShiftScheduleSettingsScreenState extends State<ShiftScheduleSettingsScreen> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  final _graceController = TextEditingController(text: '15');
  final _halfDayController = TextEditingController(text: '4');
  final _fullDayController = TextEditingController(text: '8');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.enterpriseData ?? widget.initialData ?? {};
    final shiftMap = d['shiftSchedule'] as Map<String, dynamic>?;
    if (shiftMap != null) {
      final s = ShiftSchedule.fromJson(shiftMap);
      _startTime = TimeOfDay(hour: s.startHour, minute: s.startMinute);
      _endTime = TimeOfDay(hour: s.endHour, minute: s.endMinute);
      _graceController.text = s.gracePeriodMinutes.toString();
      _halfDayController.text = (s.halfDayMinutes ~/ 60).toString();
      _fullDayController.text = (s.fullDayMinutes ~/ 60).toString();
    }
  }

  @override
  void dispose() {
    _graceController.dispose();
    _halfDayController.dispose();
    _fullDayController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _saveSettings() async {
    final grace = int.tryParse(_graceController.text.trim()) ?? 15;
    final halfDay = int.tryParse(_halfDayController.text.trim()) ?? 4;
    final fullDay = int.tryParse(_fullDayController.text.trim()) ?? 8;
    final statusTheme = context.status;

    final schedule = ShiftSchedule(
      shiftName: 'General Shift',
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      gracePeriodMinutes: grace,
      halfDayMinutes: halfDay * 60,
      fullDayMinutes: fullDay * 60,
    );

    final hasNet = await NetworkConnectionService.checkConnectionAndNotify(context);
    if (!hasNet) return;

    setState(() => _isSaving = true);
    try {
      await DatabaseService().updateEnterpriseShift(
        enterpriseId: widget.enterpriseId,
        schedule: schedule,
      );

      AuditLogService().logAction(
        enterpriseId: widget.enterpriseId,
        action: AuditLogService.actionShiftPolicyUpdated,
        category: AuditLogService.categoryPolicy,
        details: 'Shift schedule updated: ${_formatTime(_startTime)} to ${_formatTime(_endTime)}, Grace: ${grace}m.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Shift schedule and attendance policy saved!'),
            backgroundColor: statusTheme.success.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving shift schedule: $e'),
            backgroundColor: statusTheme.danger.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(
          'Work Shift & Policy',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surfaceContainerLowest,
        elevation: 0,
        foregroundColor: colors.onSurface,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timing Picker Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Standard Office Timings',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Set start and end hours for your organization.',
                    style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickTime(true),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.wb_sunny_outlined, size: AppSizes.iconSm, color: colors.tertiary),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Shift Start',
                                        style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatTime(_startTime),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickTime(false),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.nightlight_outlined, size: AppSizes.iconSm, color: colors.primary),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Shift End',
                                        style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatTime(_endTime),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Policy Thresholds Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grace & Hours Policy',
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _graceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Late Grace Period',
                      hintText: 'e.g. 15',
                      suffixText: 'minutes',
                      prefixIcon: const Icon(Icons.timer_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _halfDayController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Half-Day Minimum Hours',
                      hintText: 'e.g. 4',
                      suffixText: 'hours',
                      prefixIcon: const Icon(Icons.hourglass_bottom),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _fullDayController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Full-Day Target Hours',
                      hintText: 'e.g. 8',
                      suffixText: 'hours',
                      prefixIcon: const Icon(Icons.verified_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save Button
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? SizedBox(
                      width: AppSizes.iconMd,
                      height: AppSizes.iconMd,
                      child: CircularProgressIndicator(color: colors.onPrimary, strokeWidth: 2),
                    )
                  : Text(
                      'Save Shift Policy',
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
