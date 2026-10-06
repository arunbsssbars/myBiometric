/// Represents expected gold-standard configuration parameters for physical biometric terminals
class TerminalConfigBaseline {
  final String firmwareVersionRequired;
  final String expectedTimezone;
  final bool requireFaceRecognition;
  final bool requireTamperAlarm;
  final int maxHeartbeatIntervalSeconds;

  const TerminalConfigBaseline({
    required this.firmwareVersionRequired,
    required this.expectedTimezone,
    this.requireFaceRecognition = true,
    this.requireTamperAlarm = true,
    this.maxHeartbeatIntervalSeconds = 60,
  });

  Map<String, dynamic> toMap() {
    return {
      'firmwareVersionRequired': firmwareVersionRequired,
      'expectedTimezone': expectedTimezone,
      'requireFaceRecognition': requireFaceRecognition,
      'requireTamperAlarm': requireTamperAlarm,
      'maxHeartbeatIntervalSeconds': maxHeartbeatIntervalSeconds,
    };
  }
}

/// Discovered configuration discrepancies / drift on a live device
class TerminalDriftReport {
  final String deviceId;
  final bool hasDrift;
  final List<String> driftDiscrepancies;
  final DateTime evaluatedAt;

  const TerminalDriftReport({
    required this.deviceId,
    required this.hasDrift,
    required this.driftDiscrepancies,
    required this.evaluatedAt,
  });
}
