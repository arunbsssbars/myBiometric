import 'package:flutter/material.dart';
import '../services/shift_bidding_marketplace_service.dart';
import '../core/design_system/design_system.dart';

class ShiftBiddingMarketplaceCard extends StatelessWidget {
  final OpenShiftListing listing;
  final int totalBids;
  final VoidCallback? onBid;

  const ShiftBiddingMarketplaceCard({
    super.key,
    required this.listing,
    this.totalBids = 0,
    this.onBid,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isOpen = listing.isOpen;

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOpen ? Colors.amber.shade300 : colors.outlineVariant,
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
                  Icons.event_available_rounded,
                  color: isOpen ? Colors.amber.shade800 : colors.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${listing.department} • ${listing.roleRequired}',
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
                    color: (isOpen ? Colors.amber : Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOpen ? 'OPEN BIDDING' : 'AWARDED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isOpen ? Colors.amber.shade900 : colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${listing.shiftHours.toStringAsFixed(1)} hrs • Rate: ${listing.hourlyPremiumMultiplier.toStringAsFixed(1)}x • Bids: $totalBids',
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
                    '${listing.startTime.month}/${listing.startTime.day} ${listing.startTime.hour}:00 - ${listing.endTime.hour}:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOpen && onBid != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.withValues(alpha: 0.2),
                        foregroundColor: Colors.amber.shade900,
                      ),
                      onPressed: onBid,
                      child: const Text('Bid on Shift', style: TextStyle(fontSize: 12)),
                    ),
                  )
                else if (!isOpen)
                  Text(
                    'Awarded to: ${listing.awardedUserId ?? "Staff"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
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
