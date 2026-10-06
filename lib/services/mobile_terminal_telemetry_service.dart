import '../domain/models/mobile_terminal_punch_telemetry.dart';

/// Service logging and reporting terminal interaction metrics and quality
class MobileTerminalTelemetryService {
  final List<MobileTerminalPunchTelemetry> _inMemoryLogs = [];

  List<MobileTerminalPunchTelemetry> get telemetryLogs =>
      List.unmodifiable(_inMemoryLogs);

  MobileTerminalPunchTelemetry recordTelemetry({
    required String terminalId,
    required String employeeId,
    required String channelUsed,
    required int handshakeDurationMs,
    required int totalLatencyMs,
    required int signalRssiDbm,
    required bool success,
    String? failureReason,
  }) {
    final entry = MobileTerminalPunchTelemetry(
      telemetryId: 'TEL_${DateTime.now().millisecondsSinceEpoch}_${_inMemoryLogs.length}',
      terminalId: terminalId,
      employeeId: employeeId,
      channelUsed: channelUsed,
      handshakeDurationMs: handshakeDurationMs,
      totalLatencyMs: totalLatencyMs,
      signalRssiDbm: signalRssiDbm,
      success: success,
      failureReason: failureReason,
      recordedAt: DateTime.now(),
    );

    _inMemoryLogs.add(entry);
    return entry;
  }

  double calculateSuccessRate() {
    if (_inMemoryLogs.isEmpty) return 1.0;
    final successes = _inMemoryLogs.where((l) => l.success).length;
    return successes / _inMemoryLogs.length;
  }
}
