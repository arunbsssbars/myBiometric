import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';
import '../services/terminal_attendance_injector_service.dart';

/// AQIL-hardened interactive control card for recording and injecting attendance
/// directly through an external physical biometric terminal profile (MinMoe / ZKTeco).
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalHardwarePunchCard extends StatefulWidget {
  final String enterpriseId;
  final String userId;
  final String employeeId;
  final String employeeName;
  final List<BiometricTerminalDevice> availableDevices;
  final VoidCallback? onPunchSuccess;

  const TerminalHardwarePunchCard({
    super.key,
    required this.enterpriseId,
    required this.userId,
    required this.employeeId,
    required this.employeeName,
    required this.availableDevices,
    this.onPunchSuccess,
  });

  @override
  State<TerminalHardwarePunchCard> createState() => _TerminalHardwarePunchCardState();
}

class _TerminalHardwarePunchCardState extends State<TerminalHardwarePunchCard> {
  late final TerminalAttendanceInjectorService _injectorService;
  BiometricTerminalDevice? _selectedDevice;
  DeviceAuthMode _selectedAuthMode = DeviceAuthMode.face;
  bool _isInjecting = false;
  double _similarityScore = 99.4;

  @override
  void initState() {
    super.initState();
    _injectorService = TerminalAttendanceInjectorService();
    if (widget.availableDevices.isNotEmpty) {
      _selectedDevice = widget.availableDevices.first;
    }
  }

  @override
  void didUpdateWidget(TerminalHardwarePunchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedDevice == null && widget.availableDevices.isNotEmpty) {
      _selectedDevice = widget.availableDevices.first;
    }
  }

  Future<void> _executeTerminalPunch(String punchType) async {
    final colors = context.colors;
    final statusTheme = context.status;

    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an external biometric terminal.')),
      );
      return;
    }

    setState(() => _isInjecting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _injectorService.injectTerminalPunch(
        enterpriseId: widget.enterpriseId,
        device: _selectedDevice!,
        userId: widget.userId,
        employeeId: widget.employeeId,
        employeeName: widget.employeeName,
        punchType: punchType,
        authMode: _selectedAuthMode,
        similarityScore: _similarityScore,
      );

      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: colors.onPrimary, size: AppSizes.iconSm),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    result.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: statusTheme.success.color,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onPunchSuccess?.call();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Terminal injection failed: $e'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isInjecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    if (widget.availableDevices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(Icons.devices_other_rounded, size: 36, color: colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No Hardware Terminals Available',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Register a Hikvision MinMoe or ZKTeco machine in Admin Settings to enable physical terminal punches.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final activeDevice = _selectedDevice ?? widget.availableDevices.first;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Machine Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl - 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.fingerprint_rounded, color: colors.primary, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHYSICAL TERMINAL BRIDGE',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        activeDevice.name,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: statusTheme.success.container,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: statusTheme.success.border),
                  ),
                  child: Text(
                    'LINKED',
                    style: textTheme.labelSmall?.copyWith(
                      color: statusTheme.success.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Machine Selector
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<BiometricTerminalDevice>(
                        initialValue: activeDevice,
                        decoration: InputDecoration(
                          labelText: 'Target Biometric Machine',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                        ),
                        items: widget.availableDevices.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(
                              '${d.name} (${d.modelName})',
                              style: textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDevice = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Biometric Auth Mode Selector
                Text(
                  'Hardware Auth Method',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _buildAuthModeChip(DeviceAuthMode.face, 'Face Scan', Icons.face_rounded),
                    _buildAuthModeChip(DeviceAuthMode.fingerprint, 'Fingerprint', Icons.fingerprint_rounded),
                    _buildAuthModeChip(DeviceAuthMode.card, 'RFID Badge', Icons.credit_card_rounded),
                    _buildAuthModeChip(DeviceAuthMode.pin, 'Terminal PIN', Icons.pin_rounded),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Hardware Live Connection Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Icon(Icons.hub_rounded, size: AppSizes.iconSm, color: colors.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${activeDevice.modelName} • ${activeDevice.ipAddress}:${activeDevice.port} • Score: ${_similarityScore.toStringAsFixed(1)}%',
                          style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Action Buttons
                if (_isInjecting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: statusTheme.success.color,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          ),
                          icon: const Icon(Icons.login_rounded, size: AppSizes.iconSm),
                          label: const Text('Punch In'),
                          onPressed: () => _executeTerminalPunch('PUNCH_IN'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.error,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: AppSizes.iconSm),
                          label: const Text('Punch Out'),
                          onPressed: () => _executeTerminalPunch('PUNCH_OUT'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthModeChip(DeviceAuthMode mode, String label, IconData icon) {
    final isSelected = _selectedAuthMode == mode;
    return ChoiceChip(
      avatar: Icon(icon, size: AppSizes.iconXs),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedAuthMode = mode),
    );
  }
}
