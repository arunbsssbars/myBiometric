import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/zkteco_adms_profile.dart';
import 'package:mybiometric/services/zkteco_adms_protocol_service.dart';

void main() {
  group('ZktecoAdmsProtocolService Suite', () {
    const profile = ZktecoAdmsProfile(
      deviceSerialNumber: 'CK99882201',
      deviceIp: '192.168.1.160',
      serverUrl: 'http://push.server.corp',
      heartbeatIntervalSeconds: 45,
      delayLogTransmissionSeconds: 2,
      realTimePushEnabled: true,
      biometricTemplateSyncEnabled: true,
      timezoneOffsetMinutes: 330,
    );

    test('Generates standard ADMS cdata GET option configuration block', () {
      final response = ZktecoAdmsProtocolService.instance.generateInitResponse(profile);

      expect(response.contains('GET OPTION FROM: CK99882201'), isTrue);
      expect(response.contains('TransInterval=45'), isTrue);
      expect(response.contains('Realtime=1'), isTrue);
      expect(response.contains('Delay=2'), isTrue);
    });

    test('Parses incoming tab-delimited ATTLOG punch lines into structured records', () {
      const attlog = '101\t2026-10-05 08:30:15\t0\t15\t0\t0\t0\n'
          '102\t2026-10-05 08:31:00\t1\t1\t0\t0\t0';

      final records = ZktecoAdmsProtocolService.instance.parseAttendanceLogs(attlog);

      expect(records.length, equals(2));
      expect(records[0]['employeeId'], equals('101'));
      expect(records[0]['type'], equals('PUNCH_IN'));
      expect(records[0]['verifyType'], equals('FACE_ID'));

      expect(records[1]['employeeId'], equals('102'));
      expect(records[1]['type'], equals('PUNCH_OUT'));
      expect(records[1]['verifyType'], equals('FINGERPRINT'));
    });

    test('Generates standard acknowledgment response', () {
      final ack = ZktecoAdmsProtocolService.instance.generateAckResponse(5);
      expect(ack, equals('OK: 5'));
    });
  });
}
