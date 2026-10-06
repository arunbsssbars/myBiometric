import '../domain/models/zkteco_adms_profile.dart';

/// Service managing ZKTeco ADMS /iclock/cdata HTTP push protocol interactions
class ZktecoAdmsProtocolService {
  ZktecoAdmsProtocolService._internal();
  static final ZktecoAdmsProtocolService instance = ZktecoAdmsProtocolService._internal();

  /// Generates the standard initialization response for machine GET /iclock/cdata?SN=...
  String generateInitResponse(ZktecoAdmsProfile profile) {
    return [
      'GET OPTION FROM: ${profile.deviceSerialNumber}',
      'Stamp=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      'OpStamp=0',
      'ErrorDelay=60',
      'Delay=${profile.delayLogTransmissionSeconds}',
      'TransTimes=00:00;14:00',
      'TransInterval=${profile.heartbeatIntervalSeconds}',
      'TransFlag=1111111111',
      'TimeZone=${profile.timezoneOffsetMinutes ~/ 60}',
      'Realtime=${profile.realTimePushEnabled ? 1 : 0}',
      'Encrypt=0',
    ].join('\n');
  }

  /// Parses incoming ATTLOG punch lines formatted like:
  /// `101\t2026-10-05 08:30:15\t1\t1\t0\t0\t0`
  List<Map<String, dynamic>> parseAttendanceLogs(String rawAttlogBody) {
    final logs = <Map<String, dynamic>>[];
    final lines = rawAttlogBody.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split('\t');
      if (parts.length >= 2) {
        final pin = parts[0].trim();
        final timeStr = parts[1].trim();
        final state = parts.length > 2 ? parts[2].trim() : '0'; // 0 = In, 1 = Out
        final verifyType = parts.length > 3 ? parts[3].trim() : '1'; // 1 = Finger, 15 = Face

        logs.add({
          'employeeId': pin,
          'timestamp': timeStr,
          'type': state == '1' ? 'PUNCH_OUT' : 'PUNCH_IN',
          'verifyType': _mapVerifyType(verifyType),
        });
      }
    }
    return logs;
  }

  String _mapVerifyType(String code) {
    switch (code) {
      case '1':
        return 'FINGERPRINT';
      case '15':
        return 'FACE_ID';
      case '2':
        return 'PIN_CODE';
      case '4':
        return 'RFID_CARD';
      default:
        return 'BIOMETRIC_OTHER';
    }
  }

  /// Generates standard confirmation ACK response string for POST /iclock/cdata
  String generateAckResponse(int processedRecords) {
    return 'OK: $processedRecords';
  }
}
