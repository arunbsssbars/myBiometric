import '../domain/models/external_hardware_fleet_summary.dart';

/// Unified fleet management facade providing enterprise orchestration across all physical biometric terminals
class ExternalHardwareFleetManagerService {
  ExternalHardwareFleetManagerService._internal();
  static final ExternalHardwareFleetManagerService instance = ExternalHardwareFleetManagerService._internal();

  /// Synthesizes real-time fleet health metrics across disparate terminal protocols
  ExternalHardwareFleetSummary aggregateFleetStatus({
    required int totalDevices,
    required int onlineDevices,
    required int hikvisionCount,
    required int zktecoCount,
    required int dailyPunches,
    required int blockedSpoofs,
    required double avgLatencyMs,
  }) {
    return ExternalHardwareFleetSummary(
      totalTerminals: totalDevices,
      activeOnlineTerminals: onlineDevices,
      hikvisionMinMoeCount: hikvisionCount,
      zktecoAdmsCount: zktecoCount,
      otherManufacturersCount: (totalDevices - (hikvisionCount + zktecoCount)).clamp(0, totalDevices),
      totalDailyHardwarePunches: dailyPunches,
      antiSpoofAttacksBlocked: blockedSpoofs,
      averageHardwareLatencyMs: avgLatencyMs,
      aggregatedAt: DateTime.now(),
    );
  }
}
