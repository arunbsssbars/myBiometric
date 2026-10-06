import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_batch_config.dart';
import '../services/terminal_firmware_manager_service.dart';

/// Responsive bottom sheet for configuring fleet-wide hardware parameters
/// (Face match confidence threshold, Anti-spoofing sensitivity, NTP server, Door duration).
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalBatchConfigSheet extends StatefulWidget {
  final String enterpriseId;
  final List<BiometricTerminalDevice> devices;
  final VoidCallback? onConfigApplied;

  const TerminalBatchConfigSheet({
    super.key,
    required this.enterpriseId,
    required this.devices,
    this.onConfigApplied,
  });

  @override
  State<TerminalBatchConfigSheet> createState() => _TerminalBatchConfigSheetState();
}

class _TerminalBatchConfigSheetState extends State<TerminalBatchConfigSheet> {
  late TerminalFirmwareManagerService _managerService;
  late TextEditingController _ntpCtrl;
  late TextEditingController _osdBannerCtrl;
  double _faceThreshold = 90.0;
  String _antiSpoofing = 'HIGH';
  double _doorDuration = 5.0;
  bool _isPushing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _managerService = TerminalFirmwareManagerService();
    _ntpCtrl = TextEditingController(text: 'time.google.com');
    _osdBannerCtrl = TextEditingController(text: 'Authorized Personnel Only');
  }

  @override
  void dispose() {
    _ntpCtrl.dispose();
    _osdBannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pushConfig() async {
    setState(() {
      _isPushing = true;
      _statusMessage = null;
    });

    final cfg = TerminalBatchConfig(
      ntpServerUrl: _ntpCtrl.text.trim(),
      faceMatchThreshold: _faceThreshold.toInt(),
      antiSpoofingLevel: _antiSpoofing,
      osdBannerText: _osdBannerCtrl.text.trim(),
      doorOpenDurationSeconds: _doorDuration.toInt(),
    );

    final res = await _managerService.pushBatchConfig(
      enterpriseId: widget.enterpriseId,
      devices: widget.devices,
      config: cfg,
    );

    if (mounted) {
      setState(() {
        _isPushing = false;
        _statusMessage = 'Configuration applied to ${res.devicesConfigured} hardware machines.';
      });
      widget.onConfigApplied?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

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
              // Drag Handle
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
                    child: Icon(Icons.tune_rounded, color: colors.primary, size: AppSizes.iconMd),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fleet Batch Configuration',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Apply settings to ${widget.devices.length} biometric terminals',
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

              // Face Matching Threshold Slider
              Text(
                'Biometric Matching Threshold (${_faceThreshold.toInt()}%)',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Slider.adaptive(
                value: _faceThreshold,
                min: 80.0,
                max: 99.0,
                divisions: 19,
                activeColor: colors.primary,
                label: '${_faceThreshold.toInt()}%',
                onChanged: (val) => setState(() => _faceThreshold = val),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Anti-Spoofing Sensitivity
              Text(
                'Liveness Anti-Spoofing Level',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _antiSpoofing,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                items: const [
                  DropdownMenuItem(value: 'HIGH', child: Text('HIGH (Dual IR + RGB Liveness)')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM (Standard Depth Check)')),
                  DropdownMenuItem(value: 'LOW', child: Text('LOW (High Throughput)')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _antiSpoofing = v);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // NTP Time Server
              Text(
                'NTP Synchronization Server',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _ntpCtrl,
                decoration: InputDecoration(
                  hintText: 'time.google.com or pool.ntp.org',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  isDense: true,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Door Relay Duration Slider
              Text(
                'Door Relay Pulse Duration (${_doorDuration.toInt()}s)',
                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Slider.adaptive(
                value: _doorDuration,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                activeColor: statusTheme.success.color,
                label: '${_doorDuration.toInt()}s',
                onChanged: (val) => setState(() => _doorDuration = val),
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: statusTheme.success.container,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: statusTheme.success.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: statusTheme.success.color, size: AppSizes.iconSm),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: textTheme.bodySmall?.copyWith(
                            color: statusTheme.success.onContainer,
                            fontWeight: FontWeight.w500,
                          ),
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
                      child: Text('Cancel', style: textTheme.labelLarge),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isPushing ? null : _pushConfig,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      ),
                      icon: _isPushing
                          ? SizedBox(
                              width: AppSizes.iconSm,
                              height: AppSizes.iconSm,
                              child: CircularProgressIndicator(color: colors.onPrimary, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: AppSizes.iconSm),
                      label: Text(
                        _isPushing ? 'Pushing...' : 'Deploy Config',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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
