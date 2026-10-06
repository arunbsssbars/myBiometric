import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/terminal_anti_passback_policy.dart';
import 'package:mybiometric/services/terminal_anti_passback_service.dart';

void main() {
  group('Terminal Anti-Passback & Dual Door Interlocking Suite', () {
    final testPolicy = TerminalAntiPassbackPolicy(
      id: 'apb_hq_zone',
      enterpriseId: 'ent_demo',
      zoneName: 'Server Room Vault',
      entryTerminalIds: ['term_entry_1'],
      exitTerminalIds: ['term_exit_1'],
      mode: AntiPassbackMode.strict,
      resetIntervalHours: 8,
      exemptRoles: ['super_admin'],
      dualDoorInterlocking: true,
      updatedAt: DateTime(2026, 10, 1),
    );

    test('TerminalAntiPassbackPolicy serializes and deserializes accurately', () {
      final json = testPolicy.toJson();
      final reconstructed = TerminalAntiPassbackPolicy.fromJson(json);

      expect(reconstructed.id, equals('apb_hq_zone'));
      expect(reconstructed.zoneName, equals('Server Room Vault'));
      expect(reconstructed.mode, equals(AntiPassbackMode.strict));
      expect(reconstructed.dualDoorInterlocking, isTrue);
      expect(reconstructed.exemptRoles, contains('super_admin'));
    });

    test('TerminalAntiPassbackService detects double entry violation under strict mode', () async {
      final service = TerminalAntiPassbackService();

      // First IN scan -> Valid
      final firstIn = await service.evaluatePassback(
        enterpriseId: 'ent_demo',
        employeeId: 'EMP-404',
        terminalId: 'term_entry_1',
        punchType: 'PUNCH_IN',
        policy: testPolicy,
      );
      expect(firstIn.isAllowed, isTrue);
      expect(firstIn.isViolation, isFalse);

      // Second consecutive IN scan -> Blocked in strict mode
      final secondIn = await service.evaluatePassback(
        enterpriseId: 'ent_demo',
        employeeId: 'EMP-404',
        terminalId: 'term_entry_1',
        punchType: 'PUNCH_IN',
        policy: testPolicy,
      );
      expect(secondIn.isAllowed, isFalse);
      expect(secondIn.isViolation, isTrue);
      expect(secondIn.violationType, equals('DOUBLE_ENTRY'));

      // OUT scan -> Valid transition
      final exitScan = await service.evaluatePassback(
        enterpriseId: 'ent_demo',
        employeeId: 'EMP-404',
        terminalId: 'term_exit_1',
        punchType: 'PUNCH_OUT',
        policy: testPolicy,
      );
      expect(exitScan.isAllowed, isTrue);
      expect(exitScan.isViolation, isFalse);
    });

    test('Exempt role bypasses strict Anti-Passback enforcement', () async {
      final service = TerminalAntiPassbackService();

      final firstIn = await service.evaluatePassback(
        enterpriseId: 'ent_demo',
        employeeId: 'EMP-ADMIN',
        terminalId: 'term_entry_1',
        punchType: 'PUNCH_IN',
        policy: testPolicy,
        userRole: 'super_admin',
      );
      expect(firstIn.isAllowed, isTrue);

      final secondIn = await service.evaluatePassback(
        enterpriseId: 'ent_demo',
        employeeId: 'EMP-ADMIN',
        terminalId: 'term_entry_1',
        punchType: 'PUNCH_IN',
        policy: testPolicy,
        userRole: 'super_admin',
      );
      expect(secondIn.isAllowed, isTrue);
      expect(secondIn.isViolation, isFalse);
    });
  });
}
