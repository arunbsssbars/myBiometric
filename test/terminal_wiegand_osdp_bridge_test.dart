import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_biometric_device.dart';
import 'package:mybiometric_app/domain/models/terminal_auxiliary_reader.dart';
import 'package:mybiometric_app/services/terminal_wiegand_osdp_bridge_service.dart';

void main() {
  group('Terminal Wiegand & OSDP Auxiliary Reader Bridge Suite', () {
    final testReader = TerminalAuxiliaryReaderConfig(
      id: 'aux_reader_1',
      deviceId: 'dev_hq_turnstile',
      readerName: 'Turnstile Slave Sub-reader',
      protocol: AuxiliaryReaderProtocol.wiegand26,
      facilityCode: 155,
      direction: 'ENTRY',
      createdAt: DateTime(2026, 10, 1),
    );

    final testDevice = BiometricTerminalDevice(
      id: 'dev_hq_turnstile',
      enterpriseId: 'ent_corp',
      name: 'Turnstile Main Unit',
      modelName: 'DS-K1T343MWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.88',
      createdAt: DateTime(2026, 1, 1),
    );

    test('TerminalAuxiliaryReaderConfig serializes and deserializes accurately', () {
      final json = testReader.toJson();
      final reconstructed = TerminalAuxiliaryReaderConfig.fromJson(json);

      expect(reconstructed.id, equals('aux_reader_1'));
      expect(reconstructed.facilityCode, equals(155));
      expect(reconstructed.protocol, equals(AuxiliaryReaderProtocol.wiegand26));
      expect(reconstructed.direction, equals('ENTRY'));
    });

    test('encodeWiegand26 and decodeWiegand26 maintain parity and integrity', () {
      const facilityCode = 120;
      const cardNumber = 45210;

      final bitStream = TerminalWiegandOsdpBridgeService.encodeWiegand26(
        facilityCode: facilityCode,
        cardNumber: cardNumber,
      );

      expect(bitStream.length, equals(26));

      final decoded = TerminalWiegandOsdpBridgeService.decodeWiegand26(bitStream);
      expect(decoded.isValidParity, isTrue);
      expect(decoded.facilityCode, equals(facilityCode));
      expect(decoded.cardNumber, equals(cardNumber));
    });

    test('synthesizeAuxiliaryCardEvent generates compliant terminal punch', () {
      final event = TerminalWiegandOsdpBridgeService.synthesizeAuxiliaryCardEvent(
        device: testDevice,
        reader: testReader,
        employeeId: 'EMP-7788',
        employeeName: 'Elena Rostova',
        cardNumber: 9912,
      );

      expect(event.employeeId, equals('EMP-7788'));
      expect(event.employeeName, equals('Elena Rostova'));
      expect(event.punchType, equals('PUNCH_IN'));
      expect(event.authMode, equals(DeviceAuthMode.card));
      expect(event.cardNo, equals('CARD-9912'));
      expect(event.rawPayload, contains('aux_reader_1'));
    });
  });
}
