import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/zkteco_biometric_template.dart';
import 'package:mybiometric_app/services/zkteco_template_sync_service.dart';

void main() {
  group('ZktecoTemplateSyncService Suite', () {
    const template = ZktecoBiometricTemplate(
      pin: '204',
      fingerId: 6,
      algorithm: ZkFingerprintAlgVersion.zkFinger10,
      templateBase64: 'BASE64_FINGERPRINT_TEMPLATE_REPRESENTATION_DATA',
      templateSize: 512,
      privilege: 0,
      cardNo: 'CRD99001',
    );

    test('Builds valid DATA UPDATE FINGERTMP command string', () {
      final cmd = ZktecoTemplateSyncService.instance.buildUpdateUserTemplateCommand(
        commandId: 101,
        template: template,
      );

      expect(cmd.startsWith('C:101:DATA UPDATE FINGERTMP'), isTrue);
      expect(cmd.contains('PIN=204'), isTrue);
      expect(cmd.contains('FID=6'), isTrue);
      expect(cmd.contains('Size=512'), isTrue);
      expect(cmd.contains('TMP=BASE64_FINGERPRINT_TEMPLATE_REPRESENTATION_DATA'), isTrue);
    });

    test('Builds valid DATA UPDATE USER command string with card info', () {
      final cmd = ZktecoTemplateSyncService.instance.buildUpdateUserCommand(
        commandId: 102,
        pin: '204',
        name: 'John Connor',
        privilege: 0,
        cardNo: 'CRD99001',
      );

      expect(cmd.startsWith('C:102:DATA UPDATE USER'), isTrue);
      expect(cmd.contains('PIN=204'), isTrue);
      expect(cmd.contains('Name=John Connor'), isTrue);
      expect(cmd.contains('Card=CRD99001'), isTrue);
    });

    test('Parses machine uploaded template line into model', () {
      const line = 'PIN=305\tFID=2\tSize=384\tValid=1\tTMP=RAW_BASE64_PAYLOAD_STRING';
      final parsed = ZktecoTemplateSyncService.instance.parseMachineUploadedTemplate(line);

      expect(parsed, isNotNull);
      expect(parsed!.pin, equals('305'));
      expect(parsed.fingerId, equals(2));
      expect(parsed.templateSize, equals(384));
      expect(parsed.templateBase64, equals('RAW_BASE64_PAYLOAD_STRING'));
    });
  });
}
