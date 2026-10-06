import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/mobile_terminal_sync_drain_service.dart';

void main() {
  group('MobileTerminalSyncDrainService Tests', () {
    late MobileTerminalSyncDrainService service;

    setUp(() {
      service = MobileTerminalSyncDrainService();
      service.clearQueue();
    });

    test('enqueues offline punches and drains them cleanly to terminal', () async {
      service.enqueuePunch(
        employeeId: 'EMP-1',
        enterpriseId: 'CORP-A',
        punchType: 'PUNCH_IN',
      );
      service.enqueuePunch(
        employeeId: 'EMP-2',
        enterpriseId: 'CORP-A',
        punchType: 'PUNCH_OUT',
      );

      expect(service.queuedPunches.length, 2);

      final drainedCount = await service.drainToTerminal(terminalIp: '192.168.1.100');
      expect(drainedCount, 2);
      expect(service.queuedPunches.isEmpty, true);
    });

    test('returns 0 if queue is empty', () async {
      final drainedCount = await service.drainToTerminal(terminalIp: '192.168.1.100');
      expect(drainedCount, 0);
    });
  });
}
