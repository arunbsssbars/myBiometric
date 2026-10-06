import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric/controllers/multi_terminal_punch_controller.dart';

void main() {
  group('MultiTerminalPunchController Tests', () {
    test('updates active terminal and notifies listeners', () {
      final controller = MultiTerminalPunchController();
      bool notified = false;
      controller.addListener(() => notified = true);

      controller.selectTerminal('ZK_02', 'Lobby Turnstile', 'NFC');

      expect(notified, true);
      expect(controller.session.activeTerminalId, 'ZK_02');
      expect(controller.session.activeTerminalName, 'Lobby Turnstile');
      expect(controller.session.connectionType, 'NFC');

      controller.setPunching(true, feedback: 'Communicating with ZK_02...');
      expect(controller.session.isPunching, true);
      expect(controller.session.lastPunchFeedback, 'Communicating with ZK_02...');
    });
  });
}
