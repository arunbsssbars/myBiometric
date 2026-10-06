import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/external_biometric_device.dart';
import 'package:mybiometric_app/domain/models/terminal_remote_command.dart';
import 'package:mybiometric_app/services/terminal_remote_command_service.dart';

void main() {
  group('Terminal Remote Control Command Suite', () {
    final testDevice = BiometricTerminalDevice(
      id: 'term_relay_01',
      enterpriseId: 'ent_demo',
      name: 'Main Entrance Turnstile 1',
      modelName: 'DS-K1T343MWX',
      protocol: TerminalProtocol.hikvisionIsapi,
      ipAddress: '192.168.1.105',
      createdAt: DateTime(2026, 1, 1),
    );

    test('TerminalRemoteCommandResult serializes and deserializes accurately', () {
      final now = DateTime(2026, 10, 2, 12, 0);
      final result = TerminalRemoteCommandResult(
        success: true,
        commandType: TerminalRemoteCommandType.openDoor,
        deviceId: 'term_relay_01',
        deviceName: 'Main Entrance Turnstile 1',
        statusCode: 200,
        statusString: 'Door 1 relay pulsed open for 5 seconds.',
        executedAt: now,
      );

      final json = result.toJson();
      final reconstructed = TerminalRemoteCommandResult.fromJson(json);

      expect(reconstructed.success, isTrue);
      expect(reconstructed.commandType, equals(TerminalRemoteCommandType.openDoor));
      expect(reconstructed.deviceId, equals('term_relay_01'));
      expect(reconstructed.statusCode, equals(200));
    });

    test('TerminalRemoteCommandService dispatches door open command', () async {
      final service = TerminalRemoteCommandService();
      final result = await service.executeRemoteCommand(
        enterpriseId: 'ent_demo',
        device: testDevice,
        command: TerminalRemoteCommandType.openDoor,
      );

      expect(result.success, isTrue);
      expect(result.statusString, contains('Door 1 relay pulsed open'));
      expect(result.rawResponse['isapiEndpoint'], equals('/ISAPI/AccessControl/RemoteControl/door/1'));
    });

    test('TerminalRemoteCommandService dispatches buzzer and voice prompt commands', () async {
      final service = TerminalRemoteCommandService();
      final buzzerRes = await service.executeRemoteCommand(
        enterpriseId: 'ent_demo',
        device: testDevice,
        command: TerminalRemoteCommandType.triggerBuzzer,
      );

      expect(buzzerRes.success, isTrue);
      expect(buzzerRes.rawResponse['buzzDurationMs'], equals(1000));

      final voiceRes = await service.executeRemoteCommand(
        enterpriseId: 'ent_demo',
        device: testDevice,
        command: TerminalRemoteCommandType.voicePrompt,
        voicePromptText: 'Welcome to the office.',
      );

      expect(voiceRes.success, isTrue);
      expect(voiceRes.rawResponse['voiceText'], equals('Welcome to the office.'));
    });
  });
}
