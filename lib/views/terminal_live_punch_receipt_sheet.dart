import 'package:flutter/material.dart';
import '../domain/models/terminal_live_punch_receipt.dart';

/// Modal sheet or banner displaying instant terminal receipt upon machine punch completion
class TerminalLivePunchReceiptSheet extends StatelessWidget {
  final TerminalLivePunchReceipt receipt;
  final VoidCallback? onDismiss;

  const TerminalLivePunchReceiptSheet({
    super.key,
    required this.receipt,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isGranted = receipt.accessGranted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGranted
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer,
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isGranted ? colorScheme.primary : colorScheme.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isGranted ? 'Terminal Access Confirmed' : 'Terminal Access Denied',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            receipt.displayMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Physical Machine',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                Text(
                  receipt.terminalDeviceName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDismiss ?? () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
