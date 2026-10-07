import 'package:flutter/material.dart';
import '../services/terminal_asset_scanner_service.dart';
import '../core/design_system/design_system.dart';

class TerminalAssetScannerCard extends StatelessWidget {
  final AssetCheckoutTransaction transaction;
  final VoidCallback? onReturn;

  const TerminalAssetScannerCard({
    super.key,
    required this.transaction,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRet = transaction.isReturned;

    final badgeColor = isRet ? Colors.green : Colors.deepOrange;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRet ? Icons.task_alt_rounded : Icons.handyman_rounded,
                  color: badgeColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transaction.assetName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRet ? 'RETURNED' : 'IN CUSTODY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Barcode: ${transaction.assetBarcode} • Holder: ${transaction.employeeName}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Checked out: ${transaction.checkedOutAt.hour.toString().padLeft(2, '0')}:${transaction.checkedOutAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isRet && onReturn != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: colors.primary),
                      onPressed: onReturn,
                      icon: const Icon(Icons.keyboard_return_rounded, size: 18),
                      label: const Text('Check In', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
