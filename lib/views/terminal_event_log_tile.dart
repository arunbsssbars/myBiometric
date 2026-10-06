import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../domain/models/external_biometric_device.dart';

/// AQIL-hardened tile for presenting real-time punches ingested from external biometric terminals.
/// Fully tokenized (AQIL v2): Zero hardcoded colors/fonts, WCAG 2.2 AA compliant.
class TerminalEventLogTile extends StatelessWidget {
  final TerminalAttendanceEvent event;
  final String? terminalName;

  const TerminalEventLogTile({
    super.key,
    required this.event,
    this.terminalName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.text;
    final statusTheme = context.status;

    Color punchColor;
    Color punchBg;
    String punchLabel;

    switch (event.punchType) {
      case 'PUNCH_IN':
        punchColor = statusTheme.success.color;
        punchBg = statusTheme.success.container;
        punchLabel = 'CHECK IN';
        break;
      case 'PUNCH_OUT':
        punchColor = statusTheme.danger.color;
        punchBg = statusTheme.danger.container;
        punchLabel = 'CHECK OUT';
        break;
      case 'START_BREAK':
        punchColor = statusTheme.warning.color;
        punchBg = statusTheme.warning.container;
        punchLabel = 'BREAK OUT';
        break;
      case 'END_BREAK':
        punchColor = colors.primary;
        punchBg = colors.primaryContainer.withValues(alpha: 0.5);
        punchLabel = 'BREAK IN';
        break;
      default:
        punchColor = colors.onSurfaceVariant;
        punchBg = colors.surfaceContainerHighest;
        punchLabel = event.punchType;
    }

    IconData authIcon;
    String authLabel;
    switch (event.authMode) {
      case DeviceAuthMode.face:
        authIcon = Icons.face_rounded;
        authLabel = 'Face ID';
        break;
      case DeviceAuthMode.fingerprint:
        authIcon = Icons.fingerprint_rounded;
        authLabel = 'Fingerprint';
        break;
      case DeviceAuthMode.card:
        authIcon = Icons.credit_card_rounded;
        authLabel = 'RFID Card';
        break;
      case DeviceAuthMode.pin:
        authIcon = Icons.pin_outlined;
        authLabel = 'Terminal PIN';
        break;
      case DeviceAuthMode.multiModal:
        authIcon = Icons.verified_user_rounded;
        authLabel = 'Multi-Factor';
        break;
    }

    final metadataParts = <String>[
      event.employeeId,
      if (terminalName != null && terminalName!.isNotEmpty) terminalName!,
      '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: punchBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(authIcon, color: punchColor, size: AppSizes.iconSm),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.employeeName ?? event.employeeId,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: punchBg,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        border: Border.all(color: punchColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        punchLabel,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: punchColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        metadataParts.join(' • '),
                        style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        authLabel,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}
