import '../domain/models/terminal_watchdog_incident.dart';

/// Autonomous service monitoring kiosk runtime health, triggering automated self-healing
class TerminalWatchdogService {
  TerminalWatchdogService._internal();
  static final TerminalWatchdogService instance = TerminalWatchdogService._internal();

  /// Analyzes runtime metrics and recommends immediate automated self-healing actions
  List<TerminalWatchdogIncident> evaluateMetricsAndHeal({
    required TerminalWatchdogMetrics metrics,
  }) {
    final incidents = <TerminalWatchdogIncident>[];
    final now = DateTime.now();

    // 1. Storage Exhaustion Check
    if (metrics.diskFreeMb < 100) {
      incidents.add(TerminalWatchdogIncident(
        incidentId: 'inc_disk_${now.millisecondsSinceEpoch}',
        deviceId: metrics.deviceId,
        category: 'STORAGE_EXHAUSTION',
        message: 'Available disk space critical (${metrics.diskFreeMb.toStringAsFixed(1)} MB remaining)',
        detectedAt: now,
        autoRemediated: true,
        remediationAction: 'PURGE_TEMPORARY_LOGS_AND_IMAGE_CACHE',
      ));
    }

    // 2. Camera Hardware Fault Check
    if (metrics.consecutiveCameraFailures >= 3) {
      incidents.add(TerminalWatchdogIncident(
        incidentId: 'inc_cam_${now.millisecondsSinceEpoch}',
        deviceId: metrics.deviceId,
        category: 'CAMERA_FAULT',
        message: 'Camera stream disconnected or unresponsive for ${metrics.consecutiveCameraFailures} cycles',
        detectedAt: now,
        autoRemediated: true,
        remediationAction: 'REINITIALIZE_CAMERA_CONTROLLER',
      ));
    }

    // 3. NTP Clock Drift Check
    if (metrics.ntpDriftMillis.abs() > 15000) {
      incidents.add(TerminalWatchdogIncident(
        incidentId: 'inc_ntp_${now.millisecondsSinceEpoch}',
        deviceId: metrics.deviceId,
        category: 'TIME_DRIFT',
        message: 'Terminal hardware clock drifted by ${metrics.ntpDriftMillis} ms',
        detectedAt: now,
        autoRemediated: true,
        remediationAction: 'FORCE_ENTERPRISE_NTP_SYNC',
      ));
    }

    // 4. Memory Leak / High Pressure Check
    if (metrics.ramUsagePercent > 92) {
      incidents.add(TerminalWatchdogIncident(
        incidentId: 'inc_mem_${now.millisecondsSinceEpoch}',
        deviceId: metrics.deviceId,
        category: 'MEMORY_LEAK',
        message: 'RAM utilization exceeded safety ceiling (${metrics.ramUsagePercent.toStringAsFixed(1)}%)',
        detectedAt: now,
        autoRemediated: true,
        remediationAction: 'INVOKE_IMAGE_EMBEDDING_GC_SWEEP',
      ));
    }

    return incidents;
  }
}
