import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';
import '../services/office_network_verification_service.dart';

/// Responsive Material 3 badge component showing multi-factor office verification status
/// (GPS and/or Office Wi-Fi). Adheres strictly to the AQIL responsive standard.
class OfficePresenceBadge extends StatelessWidget {
  final MultiFactorPresenceResult result;
  final VoidCallback? onRefresh;

  const OfficePresenceBadge({
    super.key,
    required this.result,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSuccess = result.isValid;

    final primaryColor = isSuccess
        ? (result.primaryChannel == 'DUAL_VERIFIED' ? context.colors.tertiary : context.status.success.color)
        : context.status.warning.color;

    final bgColor = primaryColor.withValues(alpha: 0.08);
    final borderColor = primaryColor.withValues(alpha: 0.25);

    // Build subtitle safely using AQIL single-text join
    final metaItems = <String>[];
    if (result.gpsMatched) {
      final dist = result.auditMetadata['distanceMeters'];
      if (dist is num) {
        metaItems.add('${dist.toStringAsFixed(0)}m from center');
      } else {
        metaItems.add('GPS inside perimeter');
      }
    }
    if (result.wifiMatched) {
      final ssid = result.auditMetadata['matchedSsid'] ?? 'Office Wi-Fi';
      metaItems.add('Connected to $ssid');
    }
    if (!isSuccess && result.failureReason != null) {
      metaItems.add(result.failureReason!);
    }
    final metaText = metaItems.join(' • ');

    IconData icon;
    String title;
    if (isSuccess) {
      if (result.primaryChannel == 'DUAL_VERIFIED') {
        icon = Icons.verified_user_rounded;
        title = 'Dual Verified (GPS & Office Wi-Fi)';
      } else if (result.primaryChannel == 'OFFICE_WIFI') {
        icon = Icons.wifi_protected_setup_rounded;
        title = 'Office Wi-Fi Verified';
      } else {
        icon = Icons.location_on_rounded;
        title = 'Office Geofence Verified';
      }
    } else {
      icon = Icons.location_off_rounded;
      title = 'Outside Office Boundary';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (metaText.isNotEmpty)
                  Text(
                    metaText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: primaryColor.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: Icon(Icons.refresh, size: 18, color: primaryColor),
              onPressed: onRefresh,
              tooltip: 'Re-verify presence',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
