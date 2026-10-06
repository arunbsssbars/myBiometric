/// Status of a hardware peripheral attached to the tablet/kiosk
enum PeripheralHealthState {
  healthy,
  warning,
  critical,
  disconnected,
}

/// Represents the diagnostic state of all peripheral sensors on a biometric kiosk
class KioskPeripheralStatus {
  final String kioskId;
  final PeripheralHealthState cameraStatus;
  final PeripheralHealthState thermalPrinterStatus;
  final PeripheralHealthState magneticDoorRelayStatus;
  final double cameraFps;
  final int storageFreeMb;
  final int batteryLevelPercent;
  final bool isPluggedIn;
  final DateTime lastCheckedAt;

  const KioskPeripheralStatus({
    required this.kioskId,
    required this.cameraStatus,
    required this.thermalPrinterStatus,
    required this.magneticDoorRelayStatus,
    this.cameraFps = 30.0,
    required this.storageFreeMb,
    required this.batteryLevelPercent,
    required this.isPluggedIn,
    required this.lastCheckedAt,
  });

  bool get requiresMaintenance {
    return cameraStatus == PeripheralHealthState.critical ||
        cameraStatus == PeripheralHealthState.disconnected ||
        thermalPrinterStatus == PeripheralHealthState.critical ||
        magneticDoorRelayStatus == PeripheralHealthState.critical ||
        storageFreeMb < 500;
  }
}
