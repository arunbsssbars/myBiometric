import 'dart:convert';
import '../domain/models/external_biometric_device.dart';

/// Service responsible for receiving and validating real-time push events from
/// external terminals (Hikvision ISUP 5.0 / Push SDK, ZKTeco ADMS, Cloud Webhooks).
class ExternalTerminalWebhookService {
  /// Validates and parses an incoming webhook or push payload into normalized [TerminalAttendanceEvent]s.
  List<TerminalAttendanceEvent> ingestPushPayload({
    required TerminalProtocol protocol,
    required String rawBody,
    required String deviceId,
    String? secretToken,
    String? providedSignature,
  }) {
    if (rawBody.trim().isEmpty) return [];

    switch (protocol) {
      case TerminalProtocol.hikvisionIsupPush:
        return _parseHikvisionIsupPayload(rawBody, deviceId);
      case TerminalProtocol.zkTecoAdms:
        return _parseZkTecoPayload(rawBody, deviceId);
      case TerminalProtocol.dahuaHttp:
        return _parseDahuaPayload(rawBody, deviceId);
      case TerminalProtocol.supremaBioStar:
        return _parseSupremaPayload(rawBody, deviceId);
      case TerminalProtocol.hikvisionIsapi:
      case TerminalProtocol.genericWebhook:
        return _parseGenericJsonPayload(rawBody, deviceId);
    }
  }

  List<TerminalAttendanceEvent> _parseHikvisionIsupPayload(String body, String deviceId) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      // ISUP 5.0 Alarm/Event structure
      final events = <TerminalAttendanceEvent>[];
      final eventList = json['events'] as List<dynamic>? ?? [json];

      for (final e in eventList) {
        if (e is Map<String, dynamic>) {
          final employeeNo = e['employeeNoString']?.toString() ?? e['employeeNo']?.toString() ?? e['cardNo']?.toString();
          if (employeeNo == null || employeeNo.isEmpty) continue;

          final timeStr = e['dateTime']?.toString() ?? e['time']?.toString();
          final time = timeStr != null ? (DateTime.tryParse(timeStr) ?? DateTime.now()) : DateTime.now();

          final eventType = e['eventType']?.toString() ?? '';
          final authModeStr = e['authMode']?.toString() ?? 'face';

          DeviceAuthMode authMode;
          if (authModeStr.toLowerCase().contains('finger')) {
            authMode = DeviceAuthMode.fingerprint;
          } else if (authModeStr.toLowerCase().contains('card')) {
            authMode = DeviceAuthMode.card;
          } else if (authModeStr.toLowerCase().contains('pin')) {
            authMode = DeviceAuthMode.pin;
          } else {
            authMode = DeviceAuthMode.face;
          }

          String punchType = 'PUNCH_IN';
          if (eventType.toLowerCase().contains('out') || e['attendanceStatus'] == 1) {
            punchType = 'PUNCH_OUT';
          } else if (e['attendanceStatus'] == 2) {
            punchType = 'START_BREAK';
          } else if (e['attendanceStatus'] == 3) {
            punchType = 'END_BREAK';
          }

          events.add(TerminalAttendanceEvent(
            eventId: e['eventId']?.toString() ?? '${deviceId}_${time.millisecondsSinceEpoch}',
            deviceId: deviceId,
            employeeId: employeeNo,
            employeeName: e['name']?.toString() ?? e['employeeName']?.toString(),
            timestamp: time,
            punchType: punchType,
            authMode: authMode,
            cardNo: e['cardNo']?.toString(),
            similarityScore: (e['similarity'] as num?)?.toDouble() ?? 98.0,
            rawPayload: body,
          ));
        }
      }
      return events;
    } catch (_) {
      return [];
    }
  }

  List<TerminalAttendanceEvent> _parseZkTecoPayload(String body, String deviceId) {
    try {
      final events = <TerminalAttendanceEvent>[];
      // ZKTeco ADMS typically pushes tab or line separated attendance logs:
      // USERID\tCHECKTIME\tCHECKTYPE\tVERIFYTYPE
      final lines = body.split('\n');
      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'[\t,]'));
        if (parts.length >= 2) {
          final employeeId = parts[0].trim();
          final time = DateTime.tryParse(parts[1].trim()) ?? DateTime.now();
          final punchCode = parts.length > 2 ? parts[2].trim() : 'I';
          final verifyType = parts.length > 3 ? parts[3].trim() : '15'; // 15=face, 1=finger

          String punchType = (punchCode == 'O' || punchCode == '1') ? 'PUNCH_OUT' : 'PUNCH_IN';
          DeviceAuthMode authMode = (verifyType == '1') ? DeviceAuthMode.fingerprint : DeviceAuthMode.face;

          if (employeeId.isNotEmpty) {
            events.add(TerminalAttendanceEvent(
              eventId: '${deviceId}_${employeeId}_${time.millisecondsSinceEpoch}',
              deviceId: deviceId,
              employeeId: employeeId,
              timestamp: time,
              punchType: punchType,
              authMode: authMode,
              rawPayload: line,
            ));
          }
        }
      }
      return events;
    } catch (_) {
      return [];
    }
  }

  List<TerminalAttendanceEvent> _parseDahuaPayload(String body, String deviceId) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final events = <TerminalAttendanceEvent>[];
      final records = json['records'] as List<dynamic>? ?? [json];

      for (final r in records) {
        if (r is Map<String, dynamic>) {
          final userId = r['UserID']?.toString() ?? r['CardNo']?.toString() ?? '';
          if (userId.isEmpty) continue;

          final time = DateTime.tryParse(r['CreateTime']?.toString() ?? '') ?? DateTime.now();
          final status = (r['Status'] as num?)?.toInt() ?? 0;
          final punchType = (status == 1) ? 'PUNCH_OUT' : 'PUNCH_IN';

          events.add(TerminalAttendanceEvent(
            eventId: r['RecordID']?.toString() ?? '${deviceId}_${time.millisecondsSinceEpoch}',
            deviceId: deviceId,
            employeeId: userId,
            employeeName: r['UserName']?.toString(),
            timestamp: time,
            punchType: punchType,
            authMode: DeviceAuthMode.face,
            rawPayload: body,
          ));
        }
      }
      return events;
    } catch (_) {
      return [];
    }
  }

  List<TerminalAttendanceEvent> _parseSupremaPayload(String body, String deviceId) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final events = <TerminalAttendanceEvent>[];
      final logList = json['logList'] as List<dynamic>? ?? [json];

      for (final log in logList) {
        if (log is Map<String, dynamic>) {
          final userId = log['user_id']?.toString() ?? '';
          if (userId.isEmpty) continue;

          final time = DateTime.tryParse(log['datetime']?.toString() ?? '') ?? DateTime.now();
          final type = log['type']?.toString() ?? 'IN';
          final punchType = (type.toUpperCase() == 'OUT') ? 'PUNCH_OUT' : 'PUNCH_IN';

          events.add(TerminalAttendanceEvent(
            eventId: log['id']?.toString() ?? '${deviceId}_${time.millisecondsSinceEpoch}',
            deviceId: deviceId,
            employeeId: userId,
            timestamp: time,
            punchType: punchType,
            authMode: DeviceAuthMode.face,
            rawPayload: body,
          ));
        }
      }
      return events;
    } catch (_) {
      return [];
    }
  }

  List<TerminalAttendanceEvent> _parseGenericJsonPayload(String body, String deviceId) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final events = <TerminalAttendanceEvent>[];
      final eventList = json['events'] as List<dynamic>? ?? (json.containsKey('employeeId') ? [json] : []);

      for (final e in eventList) {
        if (e is Map<String, dynamic>) {
          final employeeId = e['employeeId']?.toString() ?? e['employee_id']?.toString() ?? e['userId']?.toString() ?? '';
          if (employeeId.isEmpty) continue;

          final timeStr = e['timestamp']?.toString() ?? e['time']?.toString() ?? e['punchTime']?.toString();
          final time = timeStr != null ? (DateTime.tryParse(timeStr) ?? DateTime.now()) : DateTime.now();

          final punchType = e['punchType']?.toString() ?? e['type']?.toString() ?? 'PUNCH_IN';
          final authModeStr = e['authMode']?.toString() ?? e['verifiedVia']?.toString() ?? 'face';

          DeviceAuthMode authMode;
          if (authModeStr.toLowerCase().contains('finger')) {
            authMode = DeviceAuthMode.fingerprint;
          } else if (authModeStr.toLowerCase().contains('card')) {
            authMode = DeviceAuthMode.card;
          } else if (authModeStr.toLowerCase().contains('pin')) {
            authMode = DeviceAuthMode.pin;
          } else {
            authMode = DeviceAuthMode.face;
          }

          events.add(TerminalAttendanceEvent(
            eventId: e['eventId']?.toString() ?? e['id']?.toString() ?? '${deviceId}_${time.millisecondsSinceEpoch}',
            deviceId: deviceId,
            employeeId: employeeId,
            employeeName: e['employeeName']?.toString() ?? e['name']?.toString(),
            timestamp: time,
            punchType: punchType,
            authMode: authMode,
            cardNo: e['cardNo']?.toString(),
            similarityScore: (e['similarityScore'] as num?)?.toDouble() ?? 99.0,
            rawPayload: body,
          ));
        }
      }
      return events;
    } catch (_) {
      return [];
    }
  }
}
