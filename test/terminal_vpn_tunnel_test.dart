import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/terminal_vpn_tunnel_config.dart';
import 'package:mybiometric_app/services/terminal_vpn_tunnel_service.dart';

void main() {
  group('TerminalVpnTunnelService Suite', () {
    final tunnel = TerminalVpnTunnelConfig(
      terminalId: 'term_front_01',
      tunnelName: 'wg0',
      serverEndpoint: 'vpn.hq.internal:51820',
      terminalTunnelIp: '10.8.0.5/32',
      allowedIpsSubnet: '10.8.0.0/24',
      clientPublicKey: 'PUBKEY_CLIENT_SAMPLE_STRING_AAA=',
      keepAliveSeconds: 25,
      status: TerminalVpnTunnelStatus.connected,
      pingLatencyMs: 32,
      lastHandshake: DateTime.now().subtract(const Duration(seconds: 15)),
    );

    test('Builds valid WireGuard wg0.conf syntax', () {
      final conf = TerminalVpnTunnelService.instance.buildWireguardConfig(
        tunnel: tunnel,
        clientPrivateKey: 'PRIVKEY_CLIENT_SAMPLE_BBB=',
        serverPublicKey: 'PUBKEY_SERVER_SAMPLE_CCC=',
      );

      expect(conf.contains('[Interface]'), isTrue);
      expect(conf.contains('Address = 10.8.0.5/32'), isTrue);
      expect(conf.contains('[Peer]'), isTrue);
      expect(conf.contains('Endpoint = vpn.hq.internal:51820'), isTrue);
      expect(conf.contains('PersistentKeepalive = 25'), isTrue);
    });

    test('Calculates high tunnel health score for connected low-latency tunnel', () {
      final score = TerminalVpnTunnelService.instance.calculateTunnelHealthScore(tunnel);
      expect(score, equals(100));
      expect(tunnel.isHealthy, isTrue);
    });
  });
}
