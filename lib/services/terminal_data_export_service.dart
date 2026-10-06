import 'dart:convert';
import '../domain/models/external_biometric_device.dart';

/// Service for generating formatted terminal event audit logs, CSV timesheets,
/// and enterprise HRMS/ERP integration payloads from physical hardware biometric records.
class TerminalDataExportService {
  /// Generates a standardized CSV string representing terminal hardware attendance logs.
  static String generateTerminalEventCsv({
    required String enterpriseName,
    required List<TerminalAttendanceEvent> events,
    required List<BiometricTerminalDevice> devices,
  }) {
    final buffer = StringBuffer();
    final deviceMap = {for (final d in devices) d.id: d};

    // CSV Header with Enterprise & Hardware metadata
    buffer.writeln('# Enterprise: $enterpriseName');
    buffer.writeln('# Export Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('EventID,Timestamp,EmployeeID,EmployeeName,PunchType,TerminalID,TerminalName,Protocol,AuthMode,SimilarityScore,CardNo,DoorStatus');

    for (final event in events) {
      final dev = deviceMap[event.deviceId];
      final terminalName = dev?.name ?? 'Unknown Terminal';
      final protocolStr = dev?.protocolDisplayName ?? 'ISAPI';

      final row = [
        event.eventId,
        event.timestamp.toIso8601String(),
        '"${event.employeeId}"',
        '"${event.employeeName}"',
        event.punchType,
        event.deviceId,
        '"$terminalName"',
        '"$protocolStr"',
        event.authMode.name,
        event.similarityScore?.toStringAsFixed(1) ?? '99.0',
        event.cardNo ?? '',
        event.isDoorUnlocked ? 'OPEN' : 'LOCKED',
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Generates formatted JSON payload ready for external HRMS / payroll webhook post.
  static String generateHrmsJsonExport({
    required String enterpriseId,
    required List<TerminalAttendanceEvent> events,
  }) {
    final exportList = events.map((e) => e.toJson()).toList();
    final map = {
      'enterpriseId': enterpriseId,
      'exportedAt': DateTime.now().toIso8601String(),
      'recordCount': events.length,
      'terminalEvents': exportList,
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
