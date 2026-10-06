import '../domain/models/mobile_machine_punch_session.dart';
import 'database_service.dart';
import 'mobile_machine_anti_spoof_service.dart';
import 'mobile_terminal_telemetry_service.dart';

/// Comprehensive result of a mobile-to-machine attendance punch
class MachinePunchExecutionResult {
  final bool success;
  final String channelName;
  final String message;
  final String? punchId;
  final DateTime executedAt;

  const MachinePunchExecutionResult({
    required this.success,
    required this.channelName,
    required this.message,
    this.punchId,
    required this.executedAt,
  });
}

class MobileMachinePunchOrchestratorService {
  DatabaseService? _dbService;
  final MobileMachineAntiSpoofService _antiSpoofService;
  final MobileTerminalTelemetryService _telemetryService;

  MobileMachinePunchOrchestratorService({
    DatabaseService? dbService,
    MobileMachineAntiSpoofService? antiSpoofService,
    MobileTerminalTelemetryService? telemetryService,
  })  : _dbService = dbService,
        _antiSpoofService = antiSpoofService ?? MobileMachineAntiSpoofService(),
        _telemetryService = telemetryService ?? MobileTerminalTelemetryService();

  DatabaseService get dbService => _dbService ??= DatabaseService();

  MobileMachinePunchSession createSession({
    required String employeeId,
    required String enterpriseId,
    MobileMachinePunchChannel defaultChannel = MobileMachinePunchChannel.opticalQr,
  }) {
    return MobileMachinePunchSession(
      sessionId: 'SESS_${DateTime.now().millisecondsSinceEpoch}',
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      activeChannel: defaultChannel,
      isReady: true,
      initializedAt: DateTime.now(),
    );
  }

  /// Evaluates optimal channel given terminal capabilities and environmental signals
  MobileMachinePunchChannel selectOptimalChannel({
    required bool hasCameraView,
    required bool hasBleHardware,
    required bool hasNfcEnabled,
    required bool isConnectedToOfficeWifi,
  }) {
    if (hasCameraView) {
      return MobileMachinePunchChannel.opticalQr;
    }
    if (hasNfcEnabled) {
      return MobileMachinePunchChannel.nfcVirtualBadge;
    }
    if (hasBleHardware) {
      return MobileMachinePunchChannel.bleBeacon;
    }
    if (isConnectedToOfficeWifi) {
      return MobileMachinePunchChannel.localLanWifi;
    }
    return MobileMachinePunchChannel.keypadTotp;
  }

  /// Executes and records the physical terminal punch into the central attendance database
  Future<MachinePunchExecutionResult> executeMachinePunch({
    required String userId,
    required String employeeId,
    required String enterpriseId,
    required String employeeName,
    required String punchType, // 'PUNCH_IN' or 'PUNCH_OUT'
    required MobileMachinePunchChannel channel,
    String terminalId = 'MAIN_TERMINAL',
    String? hardwareFingerprint,
    bool phoneBiometricVerified = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = DateTime.now();

    // 1. Anti-spoofing check
    if (hardwareFingerprint != null) {
      final token = _antiSpoofService.issueAntiSpoofToken(
        employeeId: employeeId,
        enterpriseId: enterpriseId,
        hardwareFingerprint: hardwareFingerprint,
      );
      if (!_antiSpoofService.verifyAntiSpoofToken(token)) {
        stopwatch.stop();
        _telemetryService.recordTelemetry(
          terminalId: terminalId,
          employeeId: employeeId,
          channelUsed: channel.name,
          handshakeDurationMs: 0,
          totalLatencyMs: stopwatch.elapsedMilliseconds,
          signalRssiDbm: -99,
          success: false,
          failureReason: 'Anti-spoofing validation failed',
        );
        return MachinePunchExecutionResult(
          success: false,
          channelName: channel.name,
          message: 'Anti-spoofing attestation failed. Please ensure natural device motion.',
          executedAt: now,
        );
      }
    }

    try {
      final verifiedViaTag = 'EXTERNAL_MACHINE_${channel.name.toUpperCase()}';

      await dbService.logAttendance(
        userId: userId,
        enterpriseId: enterpriseId,
        type: punchType,
        verifiedVia: verifiedViaTag,
        employeeName: employeeName,
        employeeId: employeeId,
        notes: 'Punched via Mobile-to-Machine ($channel) at Terminal: $terminalId',
        workStatus: punchType == 'PUNCH_IN' ? 'PRESENT' : 'CLOCKED_OUT',
      );

      stopwatch.stop();

      _telemetryService.recordTelemetry(
        terminalId: terminalId,
        employeeId: employeeId,
        channelUsed: channel.name,
        handshakeDurationMs: 12,
        totalLatencyMs: stopwatch.elapsedMilliseconds,
        signalRssiDbm: -55,
        success: true,
      );

      return MachinePunchExecutionResult(
        success: true,
        channelName: channel.name,
        message: 'Successfully punched $punchType on terminal ($terminalId)',
        punchId: 'LOG_${now.millisecondsSinceEpoch}',
        executedAt: now,
      );
    } catch (e) {
      stopwatch.stop();
      _telemetryService.recordTelemetry(
        terminalId: terminalId,
        employeeId: employeeId,
        channelUsed: channel.name,
        handshakeDurationMs: 12,
        totalLatencyMs: stopwatch.elapsedMilliseconds,
        signalRssiDbm: -55,
        success: false,
        failureReason: e.toString(),
      );

      return MachinePunchExecutionResult(
        success: false,
        channelName: channel.name,
        message: 'Failed to record attendance punch on machine: $e',
        executedAt: now,
      );
    }
  }
}
