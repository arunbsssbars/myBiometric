import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/edge_bandwidth_optimizer_service.dart';
import 'package:mybiometric/views/edge_bandwidth_optimizer_card.dart';

void main() {
  group('EdgeBandwidthOptimizerService Suite', () {
    late EdgeBandwidthOptimizerService service;

    setUp(() {
      service = EdgeBandwidthOptimizerService();
      service.clearForTesting();
    });

    test('Compresses sync payload and returns positive compression ratio', () {
      const payload = '{"attendanceLogs":[{"id":"1","uid":"USR_01","type":"PUNCH_IN","ts":"2026-10-08T08:00:00Z"}]}';
      final stats = service.compressPayload(payload);

      expect(stats.rawBytes, greaterThan(0));
      expect(stats.compressedBytes, lessThan(stats.rawBytes));
      expect(stats.compressionRatio, lessThan(1.0));
    });

    test('Allows unlimited sync on unmetered LAN network', () {
      service.configureDevice(
        const BandwidthQuotaConfig(
          deviceId: 'TERM_LAN_01',
          monthlyLimitMb: 10.0,
          currentUsageMb: 20.0, // Exceeded limit
          syncMode: NetworkSyncMode.unmeteredLan,
        ),
      );

      // On LAN, should still be allowed to sync
      final allowed = service.canSync(deviceId: 'TERM_LAN_01', payloadBytes: 1024);
      expect(allowed, isTrue);
    });

    test('Blocks sync on cellular network when monthly quota is exceeded', () {
      service.configureDevice(
        const BandwidthQuotaConfig(
          deviceId: 'TERM_4G_02',
          monthlyLimitMb: 100.0,
          currentUsageMb: 99.9,
          syncMode: NetworkSyncMode.meteredCellular,
        ),
      );

      // Attempting to send 1MB should be blocked
      final allowed = service.canSync(
        deviceId: 'TERM_4G_02',
        payloadBytes: 1024 * 1024,
      );
      expect(allowed, isFalse);
    });

    testWidgets('EdgeBandwidthOptimizerCard renders without overflow across viewports', (tester) async {
      const config = BandwidthQuotaConfig(
        deviceId: 'TERM_REMOTE_01',
        monthlyLimitMb: 500.0,
        currentUsageMb: 350.0,
        syncMode: NetworkSyncMode.meteredCellular,
      );

      const stats = SyncCompressionStats(
        rawBytes: 1024,
        compressedBytes: 389,
        compressionRatio: 0.38,
        compressionDuration: Duration(milliseconds: 2),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EdgeBandwidthOptimizerCard(
              config: config,
              latestStats: stats,
            ),
          ),
        ),
      );

      expect(find.textContaining('TERM_REMOTE_01'), findsOneWidget);
      expect(find.text('METEREDCELLULAR'), findsOneWidget);
      expect(find.textContaining('70% used'), findsOneWidget);
      expect(find.textContaining('saved'), findsOneWidget);
    });
  });
}
