import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import '../../domain/models/terminal_vpn_tunnel_config.dart';

/// Card presenting WireGuard encrypted VPN tunnel status, latency, and throughput
class TerminalVpnTunnelCard extends StatelessWidget {
  final TerminalVpnTunnelConfig tunnel;
  final VoidCallback? onRekeyTunnel;

  const TerminalVpnTunnelCard({
    super.key,
    required this.tunnel,
    this.onRekeyTunnel,
  });

  Color _getStatusColor(BuildContext context, TerminalVpnTunnelStatus status) {
    switch (status) {
      case TerminalVpnTunnelStatus.connected:
        return context.status.success.color;
      case TerminalVpnTunnelStatus.connecting:
      case TerminalVpnTunnelStatus.rekeying:
        return context.status.warning.color;
      case TerminalVpnTunnelStatus.disconnected:
      case TerminalVpnTunnelStatus.error:
        return context.status.danger.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(context, tunnel.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vpn_lock_rounded, size: 22, color: statusColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'WireGuard VPN Tunnel',
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    tunnel.status.name.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Endpoint: ${tunnel.serverEndpoint} • VIP: ${tunnel.terminalTunnelIp} • Ping: ${tunnel.pingLatencyMs}ms',
              style: context.textStyles.bodySmall?.copyWith(color: context.colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rx / Tx', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${(tunnel.bytesReceived / 1024).toStringAsFixed(1)}KB / ${(tunnel.bytesTransmitted / 1024).toStringAsFixed(1)}KB',
                        style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Subnet', style: context.text.labelSmall?.copyWith(color: context.colors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        tunnel.allowedIpsSubnet,
                        style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
