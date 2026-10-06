import 'package:flutter/foundation.dart';
import '../domain/models/multi_terminal_punch_session.dart';

/// State management controller coordinating multi-terminal punch operations on mobile
class MultiTerminalPunchController extends ChangeNotifier {
  MultiTerminalPunchSession _session = MultiTerminalPunchSession(
    activeTerminalId: 'HIK_MINMOE_01',
    activeTerminalName: 'Main Entrance MinMoe',
    connectionType: 'BLE',
    isPunching: false,
    lastPunchFeedback: null,
    lastActionTime: DateTime.now(),
  );

  MultiTerminalPunchSession get session => _session;

  void selectTerminal(String terminalId, String name, String connectionType) {
    _session = _session.copyWith(
      activeTerminalId: terminalId,
      activeTerminalName: name,
      connectionType: connectionType,
    );
    notifyListeners();
  }

  void setPunching(bool punching, {String? feedback}) {
    _session = _session.copyWith(
      isPunching: punching,
      lastPunchFeedback: feedback,
    );
    notifyListeners();
  }
}
