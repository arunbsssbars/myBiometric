import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/services/mobile_terminal_pairing_service.dart';

void main() {
  group('MobileTerminalPairingService Tests', () {
    late MobileTerminalPairingService service;

    setUp(() {
      service = MobileTerminalPairingService();
    });

    test('creates pairing bond and allows walk-by auto punch', () {
      final bond = service.createBond(
        terminalId: 'TURNSTILE_01',
        terminalName: 'SpeedFace Main Entrance',
        employeeId: 'EMP-77',
        enterpriseId: 'CORP-HQ',
        publicDeviceKey: 'PUB_KEY_HEX_123',
      );

      expect(bond.canAutoPunchNow(), true);

      // First walk-by punch succeeds
      final success1 = service.processWalkByPunch('TURNSTILE_01');
      expect(success1, true);

      // Immediate second punch within 300s cooldown is suppressed
      final success2 = service.processWalkByPunch('TURNSTILE_01');
      expect(success2, false);
    });

    test('unbonding removes terminal from automated punch registry', () {
      service.createBond(
        terminalId: 'TURNSTILE_02',
        terminalName: 'East Gate',
        employeeId: 'EMP-77',
        enterpriseId: 'CORP-HQ',
        publicDeviceKey: 'PUB_KEY_HEX_456',
      );

      service.unbondTerminal('TURNSTILE_02');
      final result = service.processWalkByPunch('TURNSTILE_02');
      expect(result, false);
    });
  });
}
