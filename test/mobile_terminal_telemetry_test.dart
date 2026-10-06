import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/services/mobile_terminal_telemetry_service.dart';

void main() {
  group('MobileTerminalTelemetryService Tests', () {
    late MobileTerminalTelemetryService service;

    setUp(() {
      service = MobileTerminalTelemetryService();
    });

    test('records mobile punch telemetry and computes success rate accurately', () {
      service.recordTelemetry(
        terminalId: 'HIK_MINMOE_01',
        employeeId: 'EMP-01',
        channelUsed: 'BLE',
        handshakeDurationMs: 45,
        totalLatencyMs: 120,
        signalRssiDbm: -62,
        success: true,
      );

      service.recordTelemetry(
        terminalId: 'HIK_MINMOE_01',
        employeeId: 'EMP-02',
        channelUsed: 'NFC',
        handshakeDurationMs: 30,
        totalLatencyMs: 95,
        signalRssiDbm: -55,
        success: true,
      );

      service.recordTelemetry(
        terminalId: 'ZK_SPEEDFACE_02',
        employeeId: 'EMP-03',
        channelUsed: 'LAN_WIFI',
        handshakeDurationMs: 250,
        totalLatencyMs: 600,
        signalRssiDbm: -88,
        success: false,
        failureReason: 'Socket timeout',
      );

      expect(service.telemetryLogs.length, 3);
      expect((service.calculateSuccessRate() * 100).toStringAsFixed(1), '66.7');
    });
  });
}
