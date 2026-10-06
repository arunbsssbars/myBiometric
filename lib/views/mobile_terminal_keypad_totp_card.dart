import 'package:flutter/material.dart';
import '../domain/models/mobile_terminal_keypad_totp.dart';
import '../services/mobile_terminal_keypad_totp_service.dart';

/// Card component showing 6-digit dynamic OTP for punch on machine keypad
class MobileTerminalKeypadTotpCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;

  const MobileTerminalKeypadTotpCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
  });

  @override
  State<MobileTerminalKeypadTotpCard> createState() => _MobileTerminalKeypadTotpCardState();
}

class _MobileTerminalKeypadTotpCardState extends State<MobileTerminalKeypadTotpCard> {
  late final MobileTerminalKeypadTotpService _service;
  MobileTerminalKeypadTotp? _totp;

  @override
  void initState() {
    super.initState();
    _service = MobileTerminalKeypadTotpService();
    _refreshPin();
  }

  void _refreshPin() {
    setState(() {
      _totp = _service.generateKeypadPin(
        employeeId: widget.employeeId,
        enterpriseId: widget.enterpriseId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.8),
                  ),
                  child: Icon(
                    Icons.dialpad_rounded,
                    color: colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Machine Keypad Passcode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Type this 6-digit PIN into terminal keypad',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _refreshPin,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh PIN',
                ),
              ],
            ),
            if (_totp != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _totp!.pinCode.split('').join('  '),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                      color: colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Valid for ${_totp!.remainingSeconds}s',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
