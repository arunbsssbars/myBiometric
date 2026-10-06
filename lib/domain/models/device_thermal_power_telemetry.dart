import 'package:flutter/foundation.dart';

enum DevicePowerSource {
  acPower,
  batteryCharging,
  batteryDischarging,
  poeEthernet,
}

enum DeviceThermalState {
  nominal,
  fair,
  serious,
  critical,
}

/// Power, battery, and thermal telemetry emitted by field attendance hardware
@immutable
class DeviceThermalPowerTelemetry {
  final String deviceId;
  final DevicePowerSource powerSource;
  final int batteryLevelPercent;
  final double batteryTemperatureCelsius;
  final double cpuTemperatureCelsius;
  final DeviceThermalState thermalState;
  final bool isLowPowerModeActive;
  final DateTime capturedAt;

  const DeviceThermalPowerTelemetry({
    required this.deviceId,
    required this.powerSource,
    required this.batteryLevelPercent,
    required this.batteryTemperatureCelsius,
    required this.cpuTemperatureCelsius,
    required this.thermalState,
    this.isLowPowerModeActive = false,
    required this.capturedAt,
  });

  bool get isThermalThrottlingRequired =>
      thermalState == DeviceThermalState.serious ||
      thermalState == DeviceThermalState.critical;

  Map<String, dynamic> toMap() => {
        'deviceId': deviceId,
        'powerSource': powerSource.name,
        'batteryLevelPercent': batteryLevelPercent,
        'batteryTemperatureCelsius': batteryTemperatureCelsius,
        'cpuTemperatureCelsius': cpuTemperatureCelsius,
        'thermalState': thermalState.name,
        'isLowPowerModeActive': isLowPowerModeActive,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory DeviceThermalPowerTelemetry.fromMap(Map<String, dynamic> map) =>
      DeviceThermalPowerTelemetry(
        deviceId: map['deviceId'] as String? ?? '',
        powerSource: DevicePowerSource.values.firstWhere(
          (e) => e.name == map['powerSource'],
          orElse: () => DevicePowerSource.acPower,
        ),
        batteryLevelPercent: (map['batteryLevelPercent'] as num?)?.toInt() ?? 100,
        batteryTemperatureCelsius: (map['batteryTemperatureCelsius'] as num?)?.toDouble() ?? 28.0,
        cpuTemperatureCelsius: (map['cpuTemperatureCelsius'] as num?)?.toDouble() ?? 42.0,
        thermalState: DeviceThermalState.values.firstWhere(
          (e) => e.name == map['thermalState'],
          orElse: () => DeviceThermalState.nominal,
        ),
        isLowPowerModeActive: map['isLowPowerModeActive'] as bool? ?? false,
        capturedAt: map['capturedAt'] != null
            ? DateTime.tryParse(map['capturedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
