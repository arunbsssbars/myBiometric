import '../domain/models/terminal_vpn_tunnel_config.dart';

/// Service generating WireGuard configuration profiles for attendance edge terminals
class TerminalVpnTunnelService {
  TerminalVpnTunnelService._internal();
  static final TerminalVpnTunnelService instance = TerminalVpnTunnelService._internal();

  /// Generates the standard `wg0.conf` configuration profile text for the terminal
  String buildWireguardConfig({
    required TerminalVpnTunnelConfig tunnel,
    required String clientPrivateKey,
    required String serverPublicKey,
  }) {
    return '''[Interface]
PrivateKey = $clientPrivateKey
Address = ${tunnel.terminalTunnelIp}
DNS = 1.1.1.1

[Peer]
PublicKey = $serverPublicKey
Endpoint = ${tunnel.serverEndpoint}
AllowedIPs = ${tunnel.allowedIpsSubnet}
PersistentKeepalive = ${tunnel.keepAliveSeconds}''';
  }

  /// Calculates tunnel health score based on ping latency and handshake recency
  int calculateTunnelHealthScore(TerminalVpnTunnelConfig tunnel) {
    if (tunnel.status != TerminalVpnTunnelStatus.connected) return 0;
    int score = 100;
    if (tunnel.pingLatencyMs > 100) score -= 30;
    final secondsSinceHandshake = DateTime.now().difference(tunnel.lastHandshake).inSeconds;
    if (secondsSinceHandshake > 120) score -= 40;
    return score.clamp(0, 100);
  }
}
