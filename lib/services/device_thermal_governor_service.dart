import '../domain/models/device_thermal_power_telemetry.dart';

/// Service managing hardware thermal governor and camera duty-cycle power throttling
class DeviceThermalGovernorService {
  DeviceThermalGovernorService._internal();
  static final DeviceThermalGovernorService instance = DeviceThermalGovernorService._internal();

  /// Calculates dynamic camera frame rate limit to mitigate overheating
  int getTargetCameraFps(DeviceThermalPowerTelemetry telemetry) {
    if (telemetry.thermalState == DeviceThermalState.critical) {
      return 5; // Heavily throttle to prevent shutdown
    }
    if (telemetry.thermalState == DeviceThermalState.serious) {
      return 15; // Halve camera capture frequency
    }
    if (telemetry.isLowPowerModeActive && telemetry.batteryLevelPercent < 20) {
      return 15; // Conserve battery
    }
    return 30; // Full 30fps smooth capture
  }

  /// Evaluates whether non-critical background jobs (e.g. sync batches, ML vector retraining) should pause
  bool shouldPauseBackgroundHeavyTasks(DeviceThermalPowerTelemetry telemetry) {
    return telemetry.isThermalThrottlingRequired ||
        (telemetry.powerSource == DevicePowerSource.batteryDischarging &&
            telemetry.batteryLevelPercent <= 15);
  }
}
