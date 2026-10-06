import 'package:flutter_test/flutter_test.dart';
import 'package:mybiometric_app/domain/models/device_thermal_power_telemetry.dart';
import 'package:mybiometric_app/services/device_thermal_governor_service.dart';

void main() {
  group('DeviceThermalGovernorService Suite', () {
    test('Calculates camera target FPS throttle under critical heat', () {
      final criticalTelemetry = DeviceThermalPowerTelemetry(
        deviceId: 'kiosk_hot_01',
        powerSource: DevicePowerSource.acPower,
        batteryLevelPercent: 100,
        batteryTemperatureCelsius: 48.0,
        cpuTemperatureCelsius: 82.0,
        thermalState: DeviceThermalState.critical,
        capturedAt: DateTime.now(),
      );

      final fps = DeviceThermalGovernorService.instance.getTargetCameraFps(criticalTelemetry);
      expect(fps, equals(5)); // Throttled to 5fps
      expect(DeviceThermalGovernorService.instance.shouldPauseBackgroundHeavyTasks(criticalTelemetry), isTrue);
    });

    test('Permits full 30 FPS when thermal state is nominal', () {
      final nominalTelemetry = DeviceThermalPowerTelemetry(
        deviceId: 'kiosk_cool_01',
        powerSource: DevicePowerSource.poeEthernet,
        batteryLevelPercent: 100,
        batteryTemperatureCelsius: 29.0,
        cpuTemperatureCelsius: 41.0,
        thermalState: DeviceThermalState.nominal,
        capturedAt: DateTime.now(),
      );

      final fps = DeviceThermalGovernorService.instance.getTargetCameraFps(nominalTelemetry);
      expect(fps, equals(30)); // Full 30fps
      expect(DeviceThermalGovernorService.instance.shouldPauseBackgroundHeavyTasks(nominalTelemetry), isFalse);
    });
  });
}
