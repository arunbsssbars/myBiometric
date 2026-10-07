
enum IncidentCategory {
  networkPartition,
  sensorDegradation,
  powerBrownout,
  rosterDesync,
}

class DiagnosticFinding {
  final String findingId;
  final String deviceId;
  final IncidentCategory category;
  final double confidenceScore; // 0.0 - 1.0
  final String rootCauseTitle;
  final String explanation;
  final List<String> remediationSteps;
  final DateTime analyzedAt;

  const DiagnosticFinding({
    required this.findingId,
    required this.deviceId,
    required this.category,
    required this.confidenceScore,
    required this.rootCauseTitle,
    required this.explanation,
    required this.remediationSteps,
    required this.analyzedAt,
  });

  Map<String, dynamic> toJson() => {
    'findingId': findingId,
    'deviceId': deviceId,
    'category': category.name,
    'confidenceScore': confidenceScore,
    'rootCauseTitle': rootCauseTitle,
    'explanation': explanation,
    'remediationSteps': remediationSteps,
    'analyzedAt': analyzedAt.toIso8601String(),
  };

  factory DiagnosticFinding.fromJson(Map<String, dynamic> json) {
    return DiagnosticFinding(
      findingId: json['findingId'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      category: IncidentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => IncidentCategory.sensorDegradation,
      ),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.8,
      rootCauseTitle: json['rootCauseTitle'] as String? ?? 'Anomaly Detected',
      explanation: json['explanation'] as String? ?? 'Telemetry pattern anomaly',
      remediationSteps: (json['remediationSteps'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      analyzedAt: DateTime.tryParse(json['analyzedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class IncidentRootCauseDiagnosisService {
  static final IncidentRootCauseDiagnosisService _instance = IncidentRootCauseDiagnosisService._internal();
  factory IncidentRootCauseDiagnosisService() => _instance;
  IncidentRootCauseDiagnosisService._internal();

  DiagnosticFinding diagnoseTerminalState({
    required String deviceId,
    required double pingLatencyMs,
    required double packetLossPercentage,
    required double cameraLux,
    required double internalTempCelsius,
    required int consecutiveFailedRecognitions,
  }) {
    if (pingLatencyMs > 500.0 || packetLossPercentage > 30.0) {
      return DiagnosticFinding(
        findingId: 'diag_${DateTime.now().millisecondsSinceEpoch}_$deviceId',
        deviceId: deviceId,
        category: IncidentCategory.networkPartition,
        confidenceScore: 0.92,
        rootCauseTitle: 'Upstream LAN Congestion / Gateway Flapping',
        explanation: 'Average ping latency reached ${pingLatencyMs.toStringAsFixed(0)}ms with ${packetLossPercentage.toStringAsFixed(0)}% packet loss. Offline attendance queue buffer engaged.',
        remediationSteps: [
          'Verify PoE switch port speed/duplex negotiation (force 1000BASE-T)',
          'Check local firewall DNS resolution latency for cloud endpoint',
          'Inspect Ethernet cable RJ45 termination for packet CRC errors',
        ],
        analyzedAt: DateTime.now(),
      );
    }

    if (cameraLux < 30.0 && consecutiveFailedRecognitions >= 3) {
      return DiagnosticFinding(
        findingId: 'diag_${DateTime.now().millisecondsSinceEpoch}_$deviceId',
        deviceId: deviceId,
        category: IncidentCategory.sensorDegradation,
        confidenceScore: 0.88,
        rootCauseTitle: 'Insufficient Optical Illumination at Camera Entrance',
        explanation: 'Ambient illumination measured only ${cameraLux.toStringAsFixed(0)} lx, producing poor contrast and $consecutiveFailedRecognitions consecutive failed recognition events.',
        remediationSteps: [
          'Enable kiosk infrared (IR) or auxiliary white LED floodlight',
          'Clean external optical glass cover with lint-free microfiber cloth',
          'Check if physical overhead luminaire bulb has failed',
        ],
        analyzedAt: DateTime.now(),
      );
    }

    if (internalTempCelsius > 60.0) {
      return DiagnosticFinding(
        findingId: 'diag_${DateTime.now().millisecondsSinceEpoch}_$deviceId',
        deviceId: deviceId,
        category: IncidentCategory.powerBrownout,
        confidenceScore: 0.85,
        rootCauseTitle: 'SoC Thermal Throttling from High Ambient Heat',
        explanation: 'Internal processor enclosure registered ${internalTempCelsius.toStringAsFixed(1)}°C, causing frame rate throttling and recognition latency spikes.',
        remediationSteps: [
          'Shield kiosk housing from direct afternoon sunlight exposure',
          'Ensure rear enclosure heat sink ventilation fins are unblocked',
        ],
        analyzedAt: DateTime.now(),
      );
    }

    return DiagnosticFinding(
      findingId: 'diag_${DateTime.now().millisecondsSinceEpoch}_$deviceId',
      deviceId: deviceId,
      category: IncidentCategory.rosterDesync,
      confidenceScore: 0.70,
      rootCauseTitle: 'Normal Telemetry Operating Parameters',
      explanation: 'All sensor and network metrics reside within optimal enterprise operating tolerances.',
      remediationSteps: const ['No corrective action required'],
      analyzedAt: DateTime.now(),
    );
  }
}
