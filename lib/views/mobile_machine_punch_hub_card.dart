import 'package:flutter/material.dart';
import '../domain/models/mobile_machine_punch_session.dart';
import '../domain/models/mobile_optical_qr_punch_token.dart';
import '../services/mobile_machine_punch_orchestrator_service.dart';
import '../services/mobile_optical_qr_punch_service.dart';
import 'mobile_optical_qr_punch_card.dart';
import 'ble_terminal_proximity_card.dart';
import 'mobile_virtual_nfc_badge_card.dart';
import 'local_lan_machine_punch_card.dart';
import 'mobile_terminal_relay_punch_card.dart';
import 'mobile_terminal_keypad_totp_card.dart';
import 'ultrasonic_punch_chirp_card.dart';
import 'nearby_discovered_terminal_radar_card.dart';
import 'mobile_terminal_handshake_dialog.dart';

/// Unified Hub Card providing tabbed/segmented access to all mobile-to-machine punch channels
class MobileMachinePunchHubCard extends StatefulWidget {
  final String employeeId;
  final String enterpriseId;
  final String employeeName;
  final String? userId;

  const MobileMachinePunchHubCard({
    super.key,
    required this.employeeId,
    required this.enterpriseId,
    this.employeeName = 'Employee',
    this.userId,
  });

  @override
  State<MobileMachinePunchHubCard> createState() => _MobileMachinePunchHubCardState();
}

class _MobileMachinePunchHubCardState extends State<MobileMachinePunchHubCard> {
  late final MobileMachinePunchOrchestratorService _service;
  MobileMachinePunchChannel _activeChannel = MobileMachinePunchChannel.opticalQr;
  late MobileOpticalQrPunchToken _qrToken;
  bool _isExecutingAction = false;
  String? _executionFeedback;

  @override
  void initState() {
    super.initState();
    _service = MobileMachinePunchOrchestratorService();
    final session = _service.createSession(
      employeeId: widget.employeeId,
      enterpriseId: widget.enterpriseId,
    );
    _activeChannel = session.activeChannel;
    _refreshToken();
  }

  void _refreshToken() {
    setState(() {
      _qrToken = MobileOpticalQrPunchService.instance.generatePunchToken(
        employeeId: widget.employeeId,
        enterpriseId: widget.enterpriseId,
        punchType: 'PUNCH_IN',
        secretKey: 'DEFAULT_ENTERPRISE_KEY',
      );
    });
  }

  Future<void> _handleDirectPunch(String punchType) async {
    final effectiveUserId = widget.userId ?? widget.employeeId;
    setState(() {
      _isExecutingAction = true;
      _executionFeedback = null;
    });

    final res = await _service.executeMachinePunch(
      userId: effectiveUserId,
      employeeId: widget.employeeId,
      enterpriseId: widget.enterpriseId,
      employeeName: widget.employeeName,
      punchType: punchType,
      channel: _activeChannel,
    );

    if (mounted) {
      setState(() {
        _isExecutingAction = false;
        _executionFeedback = res.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Protocol Selector Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChannelChip(
                  label: 'Dynamic QR',
                  icon: Icons.qr_code_2_rounded,
                  channel: MobileMachinePunchChannel.opticalQr,
                ),
                _buildChannelChip(
                  label: 'BLE Proximity',
                  icon: Icons.bluetooth_rounded,
                  channel: MobileMachinePunchChannel.bleBeacon,
                ),
                _buildChannelChip(
                  label: 'NFC Badge',
                  icon: Icons.nfc_rounded,
                  channel: MobileMachinePunchChannel.nfcVirtualBadge,
                ),
                _buildChannelChip(
                  label: 'LAN Wi-Fi',
                  icon: Icons.lan_rounded,
                  channel: MobileMachinePunchChannel.localLanWifi,
                ),
                _buildChannelChip(
                  label: 'Door Relay',
                  icon: Icons.meeting_room_rounded,
                  channel: MobileMachinePunchChannel.remoteRelay,
                ),
                _buildChannelChip(
                  label: 'Keypad PIN',
                  icon: Icons.dialpad_rounded,
                  channel: MobileMachinePunchChannel.keypadTotp,
                ),
                _buildChannelChip(
                  label: 'Audio Chirp',
                  icon: Icons.surround_sound_rounded,
                  channel: MobileMachinePunchChannel.ultrasonicChirp,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Active Channel Sub-Card
        _buildActiveChannelContent(),
        const SizedBox(height: 12),
        // One-Touch Machine Attendance Action Buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isExecutingAction ? null : () => _handleDirectPunch('PUNCH_IN'),
                icon: _isExecutingAction
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login_rounded, size: 18),
                label: const Text(
                  'Punch IN on Machine',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isExecutingAction ? null : () => _handleDirectPunch('PUNCH_OUT'),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Punch OUT',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        if (_executionFeedback != null) ...[
          const SizedBox(height: 6),
          Text(
            _executionFeedback!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.radar_rounded, size: 16),
              label: const Text('Scan Nearby Machines'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: colorScheme.primary,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: NearbyDiscoveredTerminalRadarCard(
                      onTerminalSelected: (term) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected Machine: ${term.deviceName} (${term.ipAddress})'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Text(
              '•',
              style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
            TextButton.icon(
              icon: const Icon(Icons.lock_person_rounded, size: 16),
              label: const Text('Test Machine Trust'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: colorScheme.secondary,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => MobileTerminalHandshakeDialog(
                    terminalId: 'MAIN_TERMINAL',
                    terminalName: 'Hikvision / ZKTeco Biometric Reader',
                    employeeId: widget.employeeId,
                    enterpriseId: widget.enterpriseId,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelChip({
    required String label,
    required IconData icon,
    required MobileMachinePunchChannel channel,
  }) {
    final isSelected = _activeChannel == channel;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        onSelected: (val) {
          if (val) setState(() => _activeChannel = channel);
        },
      ),
    );
  }

  Widget _buildActiveChannelContent() {
    switch (_activeChannel) {
      case MobileMachinePunchChannel.opticalQr:
        return MobileOpticalQrPunchCard(
          token: _qrToken,
          onRefresh: _refreshToken,
        );
      case MobileMachinePunchChannel.bleBeacon:
        return BleTerminalProximityCard(
          employeeId: widget.employeeId,
          enterpriseId: widget.enterpriseId,
        );
      case MobileMachinePunchChannel.nfcVirtualBadge:
        return MobileVirtualNfcBadgeCard(
          employeeId: widget.employeeId,
          enterpriseId: widget.enterpriseId,
        );
      case MobileMachinePunchChannel.localLanWifi:
        return LocalLanMachinePunchCard(
          employeeId: widget.employeeId,
          enterpriseId: widget.enterpriseId,
        );
      case MobileMachinePunchChannel.remoteRelay:
        return MobileTerminalRelayPunchCard(
          employeeId: widget.employeeId,
          enterpriseId: widget.enterpriseId,
          terminalId: 'DEFAULT_GATE_1',
        );
      case MobileMachinePunchChannel.keypadTotp:
        return MobileTerminalKeypadTotpCard(
          employeeId: widget.employeeId,
          enterpriseId: widget.enterpriseId,
        );
      case MobileMachinePunchChannel.ultrasonicChirp:
        return UltrasonicPunchChirpCard(
          employeeId: widget.employeeId,
          enterpriseId: widget.enterpriseId,
        );
    }
  }
}
