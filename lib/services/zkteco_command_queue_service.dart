import '../domain/models/zkteco_machine_command.dart';

/// Service managing the ADMS server command buffer queried during machine GET /iclock/getrequest
class ZktecoCommandQueueService {
  ZktecoCommandQueueService._internal();
  static final ZktecoCommandQueueService instance = ZktecoCommandQueueService._internal();

  /// Builds the HTTP response body for GET /iclock/getrequest?SN=<serialNumber>
  String formatPendingCommandsResponse(List<ZktecoMachineCommand> commands) {
    if (commands.isEmpty) {
      return 'OK';
    }
    return commands.map((c) => 'C:${c.commandId}:${c.commandString}').join('\n');
  }

  /// Parses the machine confirmation response for POST /iclock/devicecmd?SN=...
  /// Format: `ID=<id>&Return=<code>&CMD=<cmd>`
  Map<String, dynamic> parseCommandResult(String body) {
    final Map<String, dynamic> result = {};
    final tokens = body.split('&');
    for (final token in tokens) {
      final pair = token.split('=');
      if (pair.length == 2) {
        result[pair[0].trim()] = pair[1].trim();
      }
    }
    return result;
  }
}
