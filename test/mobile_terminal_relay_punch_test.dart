import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/mobile_terminal_relay_punch.dart';
import 'package:mybiometric/services/mobile_terminal_relay_punch_service.dart';

void main() {
  group('MobileTerminalRelayPunchService Tests', () {
    late MobileTerminalRelayPunchService service;

    setUp(() {
      service = MobileTerminalRelayPunchService();
    });

    test('authorizes relay strike when employee is close and biometrics verified', () async {
      final punch = MobileTerminalRelayPunch(
        relayId: 'REL-001',
        terminalId: 'TERM-GATE-1',
        employeeId: 'EMP-123',
        enterpriseId: 'ENT-XYZ',
        userLatitude: 12.971600,
        userLongitude: 77.594600,
        terminalLatitude: 12.971620, // ~2.5 meters away
        terminalLongitude: 77.594610,
        biometricVerifiedOnPhone: true,
        maxAllowedDistanceMeters: 50,
        timestamp: DateTime.now(),
      );

      final canTrigger = service.canTriggerRelay(punch);
      expect(canTrigger, true);

      final executed = await service.triggerTerminalDoorRelay(punch);
      expect(executed, true);
    });

    test('denies relay strike if employee phone biometric is not verified', () async {
      final punch = MobileTerminalRelayPunch(
        relayId: 'REL-002',
        terminalId: 'TERM-GATE-1',
        employeeId: 'EMP-123',
        enterpriseId: 'ENT-XYZ',
        userLatitude: 12.971600,
        userLongitude: 77.594600,
        terminalLatitude: 12.971600,
        terminalLongitude: 77.594600,
        biometricVerifiedOnPhone: false, // Not verified
        timestamp: DateTime.now(),
      );

      final canTrigger = service.canTriggerRelay(punch);
      expect(canTrigger, false);
    });

    test('denies relay strike if employee is too far (> 50m)', () async {
      final punch = MobileTerminalRelayPunch(
        relayId: 'REL-003',
        terminalId: 'TERM-GATE-1',
        employeeId: 'EMP-123',
        enterpriseId: 'ENT-XYZ',
        userLatitude: 12.980000, // ~1 kilometer away
        userLongitude: 77.600000,
        terminalLatitude: 12.971600,
        terminalLongitude: 77.594600,
        biometricVerifiedOnPhone: true,
        maxAllowedDistanceMeters: 50,
        timestamp: DateTime.now(),
      );

      final canTrigger = service.canTriggerRelay(punch);
      expect(canTrigger, false);
    });
  });
}
