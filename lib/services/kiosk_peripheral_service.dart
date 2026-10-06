import '../domain/models/kiosk_peripheral_status.dart';

/// Diagnostic service monitoring kiosk peripheral hardware integrity
class KioskPeripheralService {
  /// Evaluates telemetry and flags operational issues
  static KioskPeripheralStatus evaluateHealth({
    required String kioskId,
    required double cameraFps,
    required bool printerHasPaper,
    required bool relayResponding,
    required int storageFreeMb,
    required int batteryPercent,
    required bool isPluggedIn,
    DateTime? checkedAt,
  }) {
    final now = checkedAt ?? DateTime.now();

    final camState = cameraFps >= 20.0
        ? PeripheralHealthState.healthy
        : (cameraFps > 0 ? PeripheralHealthState.warning : PeripheralHealthState.critical);

    final printerState = printerHasPaper
        ? PeripheralHealthState.healthy
        : PeripheralHealthState.warning;

    final relayState = relayResponding
        ? PeripheralHealthState.healthy
        : PeripheralHealthState.critical;

    return KioskPeripheralStatus(
      kioskId: kioskId,
      cameraStatus: camState,
      thermalPrinterStatus: printerState,
      magneticDoorRelayStatus: relayState,
      cameraFps: cameraFps,
      storageFreeMb: storageFreeMb,
      batteryLevelPercent: batteryPercent,
      isPluggedIn: isPluggedIn,
      lastCheckedAt: now,
    );
  }
}
