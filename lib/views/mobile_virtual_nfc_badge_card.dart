import 'package:flutter/material.dart';
import '../domain/models/mobile_virtual_nfc_badge.dart';
import '../services/mobile_nfc_hce_bridge_service.dart';

/// Card component displaying Mobile Virtual NFC Badge for tapping against terminal
class MobileVirtualNfcBadgeCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;

  const MobileVirtualNfcBadgeCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
  });

  @override
  State<MobileVirtualNfcBadgeCard> createState() => _MobileVirtualNfcBadgeCardState();
}

class _MobileVirtualNfcBadgeCardState extends State<MobileVirtualNfcBadgeCard> {
  late final MobileNfcHceBridgeService _service;
  MobileVirtualNfcBadge? _badge;
  bool _isEmulating = true;

  @override
  void initState() {
    super.initState();
    _service = MobileNfcHceBridgeService();
    _badge = _service.issueVirtualBadge(
      employeeId: widget.employeeId,
      enterpriseId: widget.enterpriseId,
    );
  }

  void _toggleEmulation() {
    setState(() {
      _isEmulating = !_isEmulating;
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
                    color: _isEmulating
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.nfc_rounded,
                    color: _isEmulating
                        ? colorScheme.secondary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virtual NFC Badge (HCE)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isEmulating
                            ? 'Tap back of phone against terminal RFID icon'
                            : 'Virtual badge emulation suspended',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isEmulating,
                  onChanged: (val) => _toggleEmulation(),
                ),
              ],
            ),
            if (_badge != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.4),
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMULATED CARD UID',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _badge!.cardUid,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.contactless_rounded,
                      size: 28,
                      color: _isEmulating ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
