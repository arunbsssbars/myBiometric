import 'package:flutter/foundation.dart';

enum DeviceHardwareManufacturer {
  hikvisionMinMoe,
  zktecoAdms,
  supremaBioStar,
  dahuaAccess,
  genericIsapi,
}

/// Unified telemetry and management facade binding all external hardware terminals
@immutable
class ExternalHardwareFleetSummary {
  final int totalTerminals;
  final int activeOnlineTerminals;
  final int hikvisionMinMoeCount;
  final int zktecoAdmsCount;
  final int otherManufacturersCount;
  final int totalDailyHardwarePunches;
  final int antiSpoofAttacksBlocked;
  final double averageHardwareLatencyMs;
  final DateTime aggregatedAt;

  const ExternalHardwareFleetSummary({
    required this.totalTerminals,
    required this.activeOnlineTerminals,
    required this.hikvisionMinMoeCount,
    required this.zktecoAdmsCount,
    this.otherManufacturersCount = 0,
    required this.totalDailyHardwarePunches,
    required this.antiSpoofAttacksBlocked,
    required this.averageHardwareLatencyMs,
    required this.aggregatedAt,
  });

  double get fleetAvailabilityPercent =>
      totalTerminals > 0 ? (activeOnlineTerminals / totalTerminals) * 100.0 : 100.0;
}
