import '../domain/models/minmoe_remote_relay_command.dart';

/// Service synthesizing ISAPI XML/JSON payloads to trigger remote door strikes and alarms
class HikvisionRelayControlService {
  HikvisionRelayControlService._internal();
  static final HikvisionRelayControlService instance = HikvisionRelayControlService._internal();

  /// Builds ISAPI XML command body for PUT /ISAPI/AccessControl/RemoteControl/door/<doorNo>
  String buildRemoteDoorControlXml(MinMoeRemoteRelayCommand command) {
    final cmdString = _mapActionToIsapiCmd(command.action);
    return '''<?xml version="1.0" encoding="UTF-8"?>
<RemoteControlDoor version="2.0" xmlns="http://www.isapi.org/ver20/XMLSchema">
  <cmd>$cmdString</cmd>
</RemoteControlDoor>''';
  }

  /// Builds ISAPI endpoint path for the command
  String buildEndpoint(String deviceIp, int port, MinMoeRemoteRelayCommand command) {
    return 'http://$deviceIp:$port/ISAPI/AccessControl/RemoteControl/door/${command.doorNo}';
  }

  String _mapActionToIsapiCmd(MinMoeRelayAction action) {
    switch (action) {
      case MinMoeRelayAction.openDoor:
        return 'open';
      case MinMoeRelayAction.closeDoor:
        return 'close';
      case MinMoeRelayAction.lockAlways:
        return 'alwaysClose';
      case MinMoeRelayAction.unlockAlways:
        return 'alwaysOpen';
      case MinMoeRelayAction.triggerDuressAlarm:
        return 'alarm';
    }
  }
}
