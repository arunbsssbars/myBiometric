import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_remote_command.dart';
import '../services/terminal_remote_command_service.dart';

/// Responsive modal bottom sheet providing real-time hardware remote control actions
/// (Door Unlock, Free Passage, Lockdown, Buzzer Test, Voice Prompt).
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalRemoteControlSheet extends StatefulWidget {
  final BiometricTerminalDevice device;
  final String enterpriseId;
  final VoidCallback? onCommandExecuted;

  const TerminalRemoteControlSheet({
    super.key,
    required this.device,
    required this.enterpriseId,
    this.onCommandExecuted,
  });

  @override
  State<TerminalRemoteControlSheet> createState() => _TerminalRemoteControlSheetState();
}

class _TerminalRemoteControlSheetState extends State<TerminalRemoteControlSheet> {
  late TerminalRemoteCommandService _remoteService;
  bool _isExecuting = false;
  String? _lastActionResult;
  bool _lastActionSuccess = true;

  @override
  void initState() {
    super.initState();
    _remoteService = TerminalRemoteCommandService();
  }

  Future<void> _runCommand(TerminalRemoteCommandType command, {String? voiceText}) async {
    setState(() {
      _isExecuting = true;
      _lastActionResult = null;
    });

    final res = await _remoteService.executeRemoteCommand(
      enterpriseId: widget.enterpriseId,
      device: widget.device,
      command: command,
      voicePromptText: voiceText,
    );

    if (mounted) {
      setState(() {
        _isExecuting = false;
        _lastActionResult = res.statusString;
        _lastActionSuccess = res.success;
      });
      widget.onCommandExecuted?.call();
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
              // Drag handle
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
                    child: Icon(Icons.settings_remote_rounded, color: colors.primary, size: AppSizes.iconMd),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remote Hardware Control',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${widget.device.name} • ${widget.device.ipAddress}',
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

              // Primary Door Relay Commands
              Text(
                'Access Control & Door Relay',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: _buildCommandButton(
                      context,
                      icon: Icons.door_front_door_outlined,
                      label: 'Unlock (5s Pulse)',
                      color: statusTheme.success.color,
                      onPressed: _isExecuting
                          ? null
                          : () => _runCommand(TerminalRemoteCommandType.openDoor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildCommandButton(
                      context,
                      icon: Icons.lock_outline_rounded,
                      label: 'Secure / Lock',
                      color: colors.primary,
                      onPressed: _isExecuting
                          ? null
                          : () => _runCommand(TerminalRemoteCommandType.closeDoor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: _buildCommandButton(
                      context,
                      icon: Icons.meeting_room_outlined,
                      label: 'Free Passage',
                      color: statusTheme.warning.color,
                      onPressed: _isExecuting
                          ? null
                          : () => _runCommand(TerminalRemoteCommandType.alwaysOpen),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildCommandButton(
                      context,
                      icon: Icons.emergency_rounded,
                      label: 'Emergency Lockdown',
                      color: statusTheme.danger.color,
                      onPressed: _isExecuting
                          ? null
                          : () => _runCommand(TerminalRemoteCommandType.alwaysClose),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Audio & Terminal Utility
              Text(
                'Hardware Audio & Diagnostic Utilities',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: _buildCommandButton(
                      context,
                      icon: Icons.volume_up_rounded,
                      label: 'Buzzer Test',
                      color: colors.tertiary,
                      onPressed: _isExecuting
                          ? null
                          : () => _runCommand(TerminalRemoteCommandType.triggerBuzzer),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildCommandButton(
                      context,
                      icon: Icons.record_voice_over_rounded,
                      label: 'Voice Prompt',
                      color: statusTheme.info.color,
                      onPressed: _isExecuting
                          ? null
                          : () => _runCommand(TerminalRemoteCommandType.voicePrompt,
                              voiceText: 'Thank you. Attendance verified.'),
                    ),
                  ),
                ],
              ),

              if (_lastActionResult != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _lastActionSuccess
                        ? statusTheme.success.container
                        : statusTheme.danger.container,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: _lastActionSuccess
                          ? statusTheme.success.color.withValues(alpha: 0.3)
                          : statusTheme.danger.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastActionSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        color: _lastActionSuccess ? statusTheme.success.color : statusTheme.danger.color,
                        size: AppSizes.iconSm,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _lastActionResult!,
                          style: textTheme.bodySmall?.copyWith(
                            color: _lastActionSuccess
                                ? statusTheme.success.onContainer
                                : statusTheme.danger.onContainer,
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

              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.surfaceContainerHighest,
                  foregroundColor: colors.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                child: Text('Close Controls', style: textTheme.labelLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final textTheme = context.text;

    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      icon: Icon(icon, size: AppSizes.iconSm),
      label: Text(
        label,
        style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
