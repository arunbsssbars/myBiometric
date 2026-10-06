import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/zkteco_machine_command.dart';
import 'package:mybiometric_app/services/zkteco_command_queue_service.dart';

void main() {
  group('ZktecoCommandQueueService Suite', () {
    test('Formats single and multiple commands into C:<id>:<cmd> newline stream', () {
      final cmds = [
        ZktecoMachineCommand(
          commandId: 101,
          deviceSerialNumber: 'SN123',
          commandString: 'REBOOT',
          createdAt: DateTime.now(),
        ),
        ZktecoMachineCommand(
          commandId: 102,
          deviceSerialNumber: 'SN123',
          commandString: 'CHECK',
          createdAt: DateTime.now(),
        ),
      ];

      final res = ZktecoCommandQueueService.instance.formatPendingCommandsResponse(cmds);

      expect(res.contains('C:101:REBOOT'), isTrue);
      expect(res.contains('C:102:CHECK'), isTrue);
    });

    test('Returns OK when no commands are buffered', () {
      final res = ZktecoCommandQueueService.instance.formatPendingCommandsResponse([]);
      expect(res, equals('OK'));
    });

    test('Parses devicecmd postback query strings accurately', () {
      const body = 'ID=101&Return=0&CMD=REBOOT';
      final parsed = ZktecoCommandQueueService.instance.parseCommandResult(body);

      expect(parsed['ID'], equals('101'));
      expect(parsed['Return'], equals('0'));
      expect(parsed['CMD'], equals('REBOOT'));
    });
  });
}
