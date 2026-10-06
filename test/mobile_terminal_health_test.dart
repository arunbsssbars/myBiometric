import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/mobile_terminal_health_service.dart';

void main() {
  group('MobileTerminalHealthService Tests', () {
    late MobileTerminalHealthService service;

    setUp(() {
      service = MobileTerminalHealthService();
    });

    test('probes terminal hardware and confirms operational status', () async {
      final probe = await service.probeTerminal('192.168.1.120', 'HIK_MINMOE_01');
      expect(probe.isOperational, true);
      expect(probe.latencyMs < 50, true);
      expect(probe.cameraFps >= 25.0, true);
    });
  });
}
