import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/external_biometric_device.dart';
import 'package:mybiometric/services/terminal_data_export_service.dart';

void main() {
  group('Terminal Data Export & HRMS Integration Suite', () {
    final testDevice = BiometricTerminalDevice(
      id: 'term_101',
      enterpriseId: 'ent_corp',
      name: 'Executive Gate 1',
      modelName: 'DS-K1T343MWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '10.0.0.55',
      createdAt: DateTime(2026, 1, 1),
    );

    final testEvent = TerminalAttendanceEvent(
      eventId: 'EVT-99901',
      deviceId: 'term_101',
      employeeId: 'EMP-007',
      employeeName: 'James Bond',
      timestamp: DateTime(2026, 10, 2, 9, 2, 15),
      punchType: 'PUNCH_IN',
      authMode: DeviceAuthMode.face,
      similarityScore: 99.7,
      cardNo: 'CARD-007',
      rawPayload: '{"mock": true}',
    );

    test('generateTerminalEventCsv produces formatted enterprise CSV with device metadata', () {
      final csv = TerminalDataExportService.generateTerminalEventCsv(
        enterpriseName: 'Acme Corp',
        events: [testEvent],
        devices: [testDevice],
      );

      expect(csv, contains('# Enterprise: Acme Corp'));
      expect(csv, contains('EventID,Timestamp,EmployeeID'));
      expect(csv, contains('EVT-99901'));
      expect(csv, contains('"James Bond"'));
      expect(csv, contains('"Executive Gate 1"'));
      expect(csv, contains('OPEN'));
      expect(csv, contains('99.7'));
    });

    test('generateHrmsJsonExport formats compliant JSON payload', () {
      final jsonStr = TerminalDataExportService.generateHrmsJsonExport(
        enterpriseId: 'ent_corp',
        events: [testEvent],
      );

      expect(jsonStr, contains('"enterpriseId": "ent_corp"'));
      expect(jsonStr, contains('"recordCount": 1'));
      expect(jsonStr, contains('"employeeName": "James Bond"'));
      expect(jsonStr, contains('"punchType": "PUNCH_IN"'));
    });
  });
}
