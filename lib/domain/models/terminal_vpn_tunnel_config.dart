import 'package:flutter/foundation.dart';

enum TerminalVpnTunnelStatus {
  connected,
  connecting,
  disconnected,
  rekeying,
  error,
}

/// Hardware WireGuard / IPsec VPN tunnel configuration linking edge biometric terminals to HQ
@immutable
class TerminalVpnTunnelConfig {
  final String terminalId;
  final String tunnelName;
  final String serverEndpoint;
  final String terminalTunnelIp;
  final String allowedIpsSubnet;
  final String clientPublicKey;
  final int keepAliveSeconds;
  final TerminalVpnTunnelStatus status;
  final int bytesReceived;
  final int bytesTransmitted;
  final int pingLatencyMs;
  final DateTime lastHandshake;

  const TerminalVpnTunnelConfig({
    required this.terminalId,
    required this.tunnelName,
    required this.serverEndpoint,
    required this.terminalTunnelIp,
    this.allowedIpsSubnet = '10.8.0.0/24',
    required this.clientPublicKey,
    this.keepAliveSeconds = 25,
    this.status = TerminalVpnTunnelStatus.connected,
    this.bytesReceived = 0,
    this.bytesTransmitted = 0,
    this.pingLatencyMs = 28,
    required this.lastHandshake,
  });

  bool get isHealthy =>
      status == TerminalVpnTunnelStatus.connected && pingLatencyMs < 200;

  Map<String, dynamic> toMap() => {
        'terminalId': terminalId,
        'tunnelName': tunnelName,
        'serverEndpoint': serverEndpoint,
        'terminalTunnelIp': terminalTunnelIp,
        'allowedIpsSubnet': allowedIpsSubnet,
        'clientPublicKey': clientPublicKey,
        'keepAliveSeconds': keepAliveSeconds,
        'status': status.name,
        'bytesReceived': bytesReceived,
        'bytesTransmitted': bytesTransmitted,
        'pingLatencyMs': pingLatencyMs,
        'lastHandshake': lastHandshake.toIso8601String(),
      };

  factory TerminalVpnTunnelConfig.fromMap(Map<String, dynamic> map) =>
      TerminalVpnTunnelConfig(
        terminalId: map['terminalId'] as String? ?? '',
        tunnelName: map['tunnelName'] as String? ?? 'wg0',
        serverEndpoint: map['serverEndpoint'] as String? ?? 'vpn.corp.internal:51820',
        terminalTunnelIp: map['terminalTunnelIp'] as String? ?? '10.8.0.2/32',
        allowedIpsSubnet: map['allowedIpsSubnet'] as String? ?? '10.8.0.0/24',
        clientPublicKey: map['clientPublicKey'] as String? ?? '',
        keepAliveSeconds: (map['keepAliveSeconds'] as num?)?.toInt() ?? 25,
        status: TerminalVpnTunnelStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => TerminalVpnTunnelStatus.connected,
        ),
        bytesReceived: (map['bytesReceived'] as num?)?.toInt() ?? 0,
        bytesTransmitted: (map['bytesTransmitted'] as num?)?.toInt() ?? 0,
        pingLatencyMs: (map['pingLatencyMs'] as num?)?.toInt() ?? 28,
        lastHandshake: map['lastHandshake'] != null
            ? DateTime.tryParse(map['lastHandshake'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
