import '../domain/models/mobile_terminal_health_probe.dart';

/// Service probing physical machine health before user attempts a punch
class MobileTerminalHealthService {
  /// Probes hardware health metrics from terminal
  Future<MobileTerminalHealthProbe> probeTerminal(String ipAddress, String terminalId) async {
    // Simulated diagnostic ping & ISAPI device status
    return MobileTerminalHealthProbe(
      terminalId: terminalId,
      ipAddress: ipAddress,
      isOnline: true,
      latencyMs: 18,
      cameraFps: 29.8,
      diskSpacePercent: 35.4,
      firmwareVersion: 'V5.1.8_build240915',
      probedAt: DateTime.now(),
    );
  }
}
