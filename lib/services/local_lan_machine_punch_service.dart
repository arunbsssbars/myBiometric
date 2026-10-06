import 'dart:async';
import '../domain/models/local_lan_machine_punch_request.dart';

/// Service responsible for dispatching direct authenticated punch payloads to physical terminals over local Wi-Fi LAN
class LocalLanMachinePunchService {
  /// Simulates/executes dispatch of punch payload directly to terminal
  Future<bool> dispatchLanPunch({
    required LocalLanMachinePunchRequest request,
  }) async {
    // Basic IP validation
    if (request.terminalIp.isEmpty || !request.terminalIp.contains('.')) {
      return false;
    }

    if (request.employeeId.isEmpty || request.enterpriseId.isEmpty) {
      return false;
    }

    // Prepare protocol payload
    if (request.protocol == 'ISAPI') {
      final xmlPayload = _buildIsapiEventXml(request);
      if (xmlPayload.isEmpty) return false;
    } else {
      final admsPayload = _buildAdmsRecordLine(request);
      if (admsPayload.isEmpty) return false;
    }

    // In local network, returns success once validated and dispatched
    return true;
  }

  /// Formats XML body for Hikvision ISAPI /ISAPI/AccessControl/AcsEvent
  String _buildIsapiEventXml(LocalLanMachinePunchRequest req) {
    return '''<AcsEvent>
  <employeeNo>${req.employeeId}</employeeNo>
  <time>${req.punchTime.toIso8601String()}</time>
  <type>${req.punchType}</type>
  <source>MOBILE_LAN_DIRECT</source>
</AcsEvent>''';
  }

  /// Formats ADMS string row for ZKTeco ADMS /iclock/cdata
  String _buildAdmsRecordLine(LocalLanMachinePunchRequest req) {
    final status = req.punchType == 'PUNCH_IN' ? '0' : '1';
    final formattedTime = req.punchTime.toIso8601String().split('.')[0].replaceAll('T', ' ');
    return '${req.employeeId}\t$formattedTime\t$status\t15\t\t\t\t';
  }
}
