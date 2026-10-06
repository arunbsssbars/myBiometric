import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/local_lan_machine_punch_request.dart';
import 'package:mybiometric_app/services/local_lan_machine_punch_service.dart';

void main() {
  group('LocalLanMachinePunchService Tests', () {
    late LocalLanMachinePunchService service;

    setUp(() {
      service = LocalLanMachinePunchService();
    });

    test('validates request and prepares ISAPI punch payload successfully', () async {
      final req = LocalLanMachinePunchRequest(
        terminalIp: '192.168.1.120',
        employeeId: 'EMP-99',
        enterpriseId: 'ENT-CORP',
        punchType: 'PUNCH_IN',
        protocol: 'ISAPI',
        punchTime: DateTime.now(),
      );

      final success = await service.dispatchLanPunch(request: req);
      expect(success, true);
    });

    test('rejects request with invalid or empty IP address', () async {
      final req = LocalLanMachinePunchRequest(
        terminalIp: '',
        employeeId: 'EMP-99',
        enterpriseId: 'ENT-CORP',
        punchType: 'PUNCH_IN',
        punchTime: DateTime.now(),
      );

      final success = await service.dispatchLanPunch(request: req);
      expect(success, false);
    });

    test('serialization roundtrip preserves request fields', () {
      final req = LocalLanMachinePunchRequest(
        terminalIp: '10.0.0.50',
        employeeId: 'EMP-88',
        enterpriseId: 'ENT-HQ',
        punchType: 'PUNCH_OUT',
        punchTime: DateTime.now(),
      );

      final map = req.toMap();
      final restored = LocalLanMachinePunchRequest.fromMap(map);

      expect(restored.terminalIp, req.terminalIp);
      expect(restored.employeeId, req.employeeId);
      expect(restored.punchType, req.punchType);
    });
  });
}
