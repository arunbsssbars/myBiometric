
enum TamperSensorType {
  chassisSwitch,
  accelerometerShock,
  opticalLightLeak,
  cableDisconnect,
}

enum TamperSeverity {
  low,
  warning,
  critical,
}

class TerminalTamperEvent {
  final String id;
  final String deviceId;
  final String enterpriseId;
  final TamperSensorType sensorType;
  final TamperSeverity severity;
  final DateTime timestamp;
  final double sensorValue;
  final String description;
  final bool acknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  const TerminalTamperEvent({
    required this.id,
    required this.deviceId,
    required this.enterpriseId,
    required this.sensorType,
    required this.severity,
    required this.timestamp,
    required this.sensorValue,
    required this.description,
    this.acknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
  });

  TerminalTamperEvent copyWith({
    bool? acknowledged,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
  }) {
    return TerminalTamperEvent(
      id: id,
      deviceId: deviceId,
      enterpriseId: enterpriseId,
      sensorType: sensorType,
      severity: severity,
      timestamp: timestamp,
      sensorValue: sensorValue,
      description: description,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId': deviceId,
    'enterpriseId': enterpriseId,
    'sensorType': sensorType.name,
    'severity': severity.name,
    'timestamp': timestamp.toIso8601String(),
    'sensorValue': sensorValue,
    'description': description,
    'acknowledged': acknowledged,
    'acknowledgedBy': acknowledgedBy,
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
  };

  factory TerminalTamperEvent.fromJson(Map<String, dynamic> json) {
    return TerminalTamperEvent(
      id: json['id'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      enterpriseId: json['enterpriseId'] as String? ?? '',
      sensorType: TamperSensorType.values.firstWhere(
        (e) => e.name == json['sensorType'],
        orElse: () => TamperSensorType.chassisSwitch,
      ),
      severity: TamperSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => TamperSeverity.warning,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      sensorValue: (json['sensorValue'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? 'Tamper alert triggered',
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedBy: json['acknowledgedBy'] as String?,
      acknowledgedAt: json['acknowledgedAt'] != null 
          ? DateTime.tryParse(json['acknowledgedAt'] as String) 
          : null,
    );
  }
}

class TerminalTamperAlertService {
  static final TerminalTamperAlertService _instance = TerminalTamperAlertService._internal();
  factory TerminalTamperAlertService() => _instance;
  TerminalTamperAlertService._internal();

  final List<TerminalTamperEvent> _events = [];

  List<TerminalTamperEvent> get events => List.unmodifiable(_events);

  TerminalTamperEvent recordIncident({
    required String deviceId,
    required String enterpriseId,
    required TamperSensorType sensorType,
    required double sensorValue,
    String? customDescription,
  }) {
    final severity = _calculateSeverity(sensorType, sensorValue);
    final description = customDescription ?? _generateDescription(sensorType, sensorValue);
    final event = TerminalTamperEvent(
      id: 'tamper_${DateTime.now().millisecondsSinceEpoch}_${_events.length}',
      deviceId: deviceId,
      enterpriseId: enterpriseId,
      sensorType: sensorType,
      severity: severity,
      timestamp: DateTime.now(),
      sensorValue: sensorValue,
      description: description,
    );
    _events.insert(0, event);
    return event;
  }

  TamperSeverity _calculateSeverity(TamperSensorType type, double value) {
    switch (type) {
      case TamperSensorType.chassisSwitch:
        return value > 0.5 ? TamperSeverity.critical : TamperSeverity.warning;
      case TamperSensorType.opticalLightLeak:
        return value > 100.0 ? TamperSeverity.critical : TamperSeverity.warning;
      case TamperSensorType.accelerometerShock:
        if (value > 4.0) return TamperSeverity.critical;
        if (value > 2.0) return TamperSeverity.warning;
        return TamperSeverity.low;
      case TamperSensorType.cableDisconnect:
        return TamperSeverity.critical;
    }
  }

  String _generateDescription(TamperSensorType type, double value) {
    switch (type) {
      case TamperSensorType.chassisSwitch:
        return 'Physical enclosure opened (Chassis microswitch triggered)';
      case TamperSensorType.opticalLightLeak:
        return 'Enclosure seal breach: Internal ambient lux registered ${value.toStringAsFixed(1)} lx';
      case TamperSensorType.accelerometerShock:
        return 'Impact shock registered ${value.toStringAsFixed(2)}g exceeding resting threshold';
      case TamperSensorType.cableDisconnect:
        return 'RJ45/PoE harness or power supply cable disconnected abnormally';
    }
  }

  bool acknowledgeAlert(String eventId, String adminUid) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return false;
    _events[index] = _events[index].copyWith(
      acknowledged: true,
      acknowledgedBy: adminUid,
      acknowledgedAt: DateTime.now(),
    );
    return true;
  }

  List<TerminalTamperEvent> getUnacknowledgedAlerts({String? deviceId}) {
    return _events.where((e) {
      final matchesDevice = deviceId == null || e.deviceId == deviceId;
      return matchesDevice && !e.acknowledged;
    }).toList();
  }

  bool isEnclosureCompromised(String deviceId) {
    return _events.any((e) => 
      e.deviceId == deviceId && 
      !e.acknowledged && 
      e.severity == TamperSeverity.critical
    );
  }

  double calculateDeviceRiskScore(String deviceId) {
    final deviceAlerts = _events.where((e) => e.deviceId == deviceId).toList();
    if (deviceAlerts.isEmpty) return 0.0;
    
    double score = 0.0;
    for (final e in deviceAlerts) {
      if (e.acknowledged) {
        score += 2.0;
      } else {
        switch (e.severity) {
          case TamperSeverity.critical:
            score += 40.0;
            break;
          case TamperSeverity.warning:
            score += 20.0;
            break;
          case TamperSeverity.low:
            score += 5.0;
            break;
        }
      }
    }
    return score.clamp(0.0, 100.0);
  }

  void clearForTesting() {
    _events.clear();
  }
}
