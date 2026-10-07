
enum PowerSourceType {
  poeStandard, // 802.3af (15.4W)
  poePlus, // 802.3at (30W)
  dcWallAdapter,
  internalBattery,
}

class TerminalPowerStatus {
  final String deviceId;
  final PowerSourceType activePowerSource;
  final double inputVoltage; // Volts e.g. 48.0V (PoE) or 12.0V (DC)
  final double currentDrawWatts;
  final double batteryPercentage; // 0.0 - 100.0
  final bool isMainPowerLost;
  final DateTime recordedAt;

  const TerminalPowerStatus({
    required this.deviceId,
    required this.activePowerSource,
    required this.inputVoltage,
    required this.currentDrawWatts,
    required this.batteryPercentage,
    required this.isMainPowerLost,
    required this.recordedAt,
  });

  bool get isCriticalBattery => isMainPowerLost && batteryPercentage < 15.0;
  bool get isLowBattery => isMainPowerLost && batteryPercentage < 30.0;

  /// Estimated runtime remaining in minutes on battery backup
  int get estimatedBatteryMinutesRemaining {
    if (!isMainPowerLost || currentDrawWatts <= 0) return 999;
    // Assuming typical 20Wh internal backup battery
    final remainingWattHours = (batteryPercentage / 100.0) * 20.0;
    return ((remainingWattHours / currentDrawWatts) * 60).round().clamp(0, 999);
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'activePowerSource': activePowerSource.name,
    'inputVoltage': inputVoltage,
    'currentDrawWatts': currentDrawWatts,
    'batteryPercentage': batteryPercentage,
    'isMainPowerLost': isMainPowerLost,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory TerminalPowerStatus.fromJson(Map<String, dynamic> json) {
    return TerminalPowerStatus(
      deviceId: json['deviceId'] as String? ?? '',
      activePowerSource: PowerSourceType.values.firstWhere(
        (e) => e.name == json['activePowerSource'],
        orElse: () => PowerSourceType.poeStandard,
      ),
      inputVoltage: (json['inputVoltage'] as num?)?.toDouble() ?? 48.0,
      currentDrawWatts: (json['currentDrawWatts'] as num?)?.toDouble() ?? 10.0,
      batteryPercentage: (json['batteryPercentage'] as num?)?.toDouble() ?? 100.0,
      isMainPowerLost: json['isMainPowerLost'] as bool? ?? false,
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TerminalPoePowerSentinelService {
  static final TerminalPoePowerSentinelService _instance = TerminalPoePowerSentinelService._internal();
  factory TerminalPoePowerSentinelService() => _instance;
  TerminalPoePowerSentinelService._internal();

  final Map<String, TerminalPowerStatus> _statusMap = {};

  void updatePowerStatus(TerminalPowerStatus status) {
    _statusMap[status.deviceId] = status;
  }

  TerminalPowerStatus getStatus(String deviceId) {
    return _statusMap[deviceId] ?? TerminalPowerStatus(
      deviceId: deviceId,
      activePowerSource: PowerSourceType.poeStandard,
      inputVoltage: 48.0,
      currentDrawWatts: 8.5,
      batteryPercentage: 100.0,
      isMainPowerLost: false,
      recordedAt: DateTime.now(),
    );
  }

  bool shouldTriggerPowerConservation(String deviceId) {
    final status = getStatus(deviceId);
    return status.isMainPowerLost && status.batteryPercentage < 25.0;
  }

  void clearForTesting() {
    _statusMap.clear();
  }
}
