import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/domain/models/minmoe_remote_relay_command.dart';
import 'package:mybiometric/services/hikvision_relay_control_service.dart';

void main() {
  group('HikvisionRelayControlService Suite', () {
    test('Builds valid ISAPI XML for openDoor command', () {
      final cmd = MinMoeRemoteRelayCommand(
        terminalId: 'term_front_01',
        doorNo: 1,
        action: MinMoeRelayAction.openDoor,
        holdOpenSeconds: 5,
        operatorUserId: 'usr_sec_admin',
        issuedAt: DateTime.now(),
      );

      final xml = HikvisionRelayControlService.instance.buildRemoteDoorControlXml(cmd);

      expect(xml.contains('<RemoteControlDoor version="2.0"'), isTrue);
      expect(xml.contains('<cmd>open</cmd>'), isTrue);
    });

    test('Maps actions to appropriate ISAPI verbs', () {
      final alarmCmd = MinMoeRemoteRelayCommand(
        terminalId: 'term_front_01',
        doorNo: 2,
        action: MinMoeRelayAction.triggerDuressAlarm,
        operatorUserId: 'usr_sec_admin',
        issuedAt: DateTime.now(),
      );

      final xml = HikvisionRelayControlService.instance.buildRemoteDoorControlXml(alarmCmd);
      expect(xml.contains('<cmd>alarm</cmd>'), isTrue);

      final endpoint = HikvisionRelayControlService.instance.buildEndpoint('192.168.1.150', 80, alarmCmd);
      expect(endpoint, equals('http://192.168.1.150:80/ISAPI/AccessControl/RemoteControl/door/2'));
    });
  });
}
