
enum SensorOperatingState {
  optimal,
  warning,
  critical,
}

class TerminalEnvironmentTelemetry {
  final String deviceId;
  final double temperatureCelsius;
  final double relativeHumidityPercent;
  final double ambientLightLux;
  final DateTime recordedAt;

  const TerminalEnvironmentTelemetry({
    required this.deviceId,
    required this.temperatureCelsius,
    required this.relativeHumidityPercent,
    required this.ambientLightLux,
    required this.recordedAt,
  });

  bool get isOverheating => temperatureCelsius > 55.0;
  bool get isSubZero => temperatureCelsius < 0.0;
  bool get isLowLight => ambientLightLux < 40.0;
  bool get isGlareCondition => ambientLightLux > 2000.0;
  bool get isHighHumidity => relativeHumidityPercent > 85.0;

  SensorOperatingState get operatingState {
    if (temperatureCelsius > 65.0 || temperatureCelsius < -10.0 || relativeHumidityPercent > 95.0) {
      return SensorOperatingState.critical;
    }
    if (isOverheating || isSubZero || isLowLight || isGlareCondition || isHighHumidity) {
      return SensorOperatingState.warning;
    }
    return SensorOperatingState.optimal;
  }

  String get environmentStatusSummary {
    if (operatingState == SensorOperatingState.critical) {
      return 'Critical Environmental Alert (Hardware threshold breached)';
    }
    if (isLowLight) {
      return 'Sub-optimal Lighting: Facial recognition accuracy may decrease (<40 lx)';
    }
    if (isGlareCondition) {
      return 'Direct Glare Detected: Optical sensor washed out (>2000 lx)';
    }
    if (isOverheating) {
      return 'Thermal Warning: Terminal approaching throttle temperature (>55°C)';
    }
    if (isHighHumidity) {
      return 'High Ingress Risk: Relative humidity exceeding 85%';
    }
    return 'Optimal Environmental Conditions';
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'temperatureCelsius': temperatureCelsius,
    'relativeHumidityPercent': relativeHumidityPercent,
    'ambientLightLux': ambientLightLux,
    'recordedAt': recordedAt.toIso8601String(),
    'operatingState': operatingState.name,
  };

  factory TerminalEnvironmentTelemetry.fromJson(Map<String, dynamic> json) {
    return TerminalEnvironmentTelemetry(
      deviceId: json['deviceId'] as String? ?? '',
      temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble() ?? 25.0,
      relativeHumidityPercent: (json['relativeHumidityPercent'] as num?)?.toDouble() ?? 50.0,
      ambientLightLux: (json['ambientLightLux'] as num?)?.toDouble() ?? 300.0,
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TerminalEnvironmentSensorService {
  static final TerminalEnvironmentSensorService _instance = TerminalEnvironmentSensorService._internal();
  factory TerminalEnvironmentSensorService() => _instance;
  TerminalEnvironmentSensorService._internal();

  final Map<String, TerminalEnvironmentTelemetry> _latestTelemetry = {};

  void recordTelemetry(TerminalEnvironmentTelemetry telemetry) {
    _latestTelemetry[telemetry.deviceId] = telemetry;
  }

  TerminalEnvironmentTelemetry? getLatest(String deviceId) => _latestTelemetry[deviceId];

  bool shouldTriggerAuxiliaryIllumination(String deviceId) {
    final telemetry = _latestTelemetry[deviceId];
    if (telemetry == null) return false;
    return telemetry.isLowLight;
  }

  void clearForTesting() {
    _latestTelemetry.clear();
  }
}
