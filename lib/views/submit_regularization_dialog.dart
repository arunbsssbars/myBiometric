import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/attendance_regularization_request.dart';
import '../services/attendance_regularization_service.dart';

/// Responsive dialog allowing employees to submit attendance regularization / correction requests.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class SubmitRegularizationDialog extends StatefulWidget {
  final String enterpriseId;
  final String userId;
  final String employeeId;
  final String employeeName;
  final VoidCallback? onSubmitted;

  const SubmitRegularizationDialog({
    super.key,
    required this.enterpriseId,
    required this.userId,
    required this.employeeId,
    required this.employeeName,
    this.onSubmitted,
  });

  @override
  State<SubmitRegularizationDialog> createState() => _SubmitRegularizationDialogState();
}

class _SubmitRegularizationDialogState extends State<SubmitRegularizationDialog> {
  late AttendanceRegularizationService _service;
  DateTime _targetDate = DateTime.now();
  TimeOfDay _checkInTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 18, minute: 0);
  RegularizationCategory _category = RegularizationCategory.forgotPunch;
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = AttendanceRegularizationService();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _selectTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime : _checkOutTime,
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Please provide an explanation.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final checkInDt = DateTime(
      _targetDate.year,
      _targetDate.month,
      _targetDate.day,
      _checkInTime.hour,
      _checkInTime.minute,
    );
    final checkOutDt = DateTime(
      _targetDate.year,
      _targetDate.month,
      _targetDate.day,
      _checkOutTime.hour,
      _checkOutTime.minute,
    );

    try {
      final req = AttendanceRegularizationRequest(
        id: '',
        enterpriseId: widget.enterpriseId,
        userId: widget.userId,
        employeeId: widget.employeeId,
        employeeName: widget.employeeName,
        targetDate: _targetDate,
        requestedCheckIn: checkInDt,
        requestedCheckOut: checkOutDt,
        category: _category,
        reasonDescription: reason,
        status: RegularizationStatus.pending,
        appliedAt: DateTime.now(),
      );

      await _service.submitRegularizationRequest(request: req);

      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onSubmitted?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Regularization request submitted successfully.'),
            backgroundColor: context.status.success.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('ArgumentError: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    final dateStr =
        '${_targetDate.day.toString().padLeft(2, '0')}/${_targetDate.month.toString().padLeft(2, '0')}/${_targetDate.year}';

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.edit_calendar_rounded, color: colors.primary, size: AppSizes.iconMd),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Regularize Attendance',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${widget.employeeName} • ${widget.employeeId}',
                          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: AppSizes.iconMd),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Date Selector
              Text('Target Date', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: AppSizes.iconSm, color: colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: colors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Shift Times Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Check-In Time', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xs),
                        InkWell(
                          onTap: () => _selectTime(true),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.login_rounded, size: 14, color: statusTheme.success.color),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  _checkInTime.format(context),
                                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Check-Out Time', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xs),
                        InkWell(
                          onTap: () => _selectTime(false),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, size: 14, color: colors.error),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  _checkOutTime.format(context),
                                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Category Selector
              Text('Correction Category', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<RegularizationCategory>(
                initialValue: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                ),
                items: RegularizationCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.label, style: textTheme.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Reason Description
              Text('Explanation / Note', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _reasonCtrl,
                maxLines: 2,
                style: textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Describe why this punch was missed...',
                  hintStyle: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  isDense: true,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: statusTheme.danger.container,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: statusTheme.danger.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: statusTheme.danger.color, size: AppSizes.iconSm),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodySmall?.copyWith(color: statusTheme.danger.color),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: AppSizes.iconSm),
                      label: Text(
                        _isSubmitting ? 'Sending...' : 'Submit Request',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
}
