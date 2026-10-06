/// Severity of a terminal hardware or network event
enum TerminalAlertSeverity {
  info,
  warning,
  critical,
}

/// Category of terminal incident
enum TerminalAlertEventType {
  heartbeatLost,
  tamperSwitchTriggered,
  cameraHardwareFault,
  lowBatteryBackup,
  rebootUnplanned,
  storageFull,
}

/// Webhook endpoint configuration for an enterprise
class TerminalWebhookEndpoint {
  final String endpointId;
  final String enterpriseId;
  final String name; // e.g. "DevOps Slack Channel", "SecOps PagerDuty"
  final String targetUrl;
  final String hmacSecret;
  final bool isEnabled;
  final List<TerminalAlertSeverity> subscribedSeverities;

  const TerminalWebhookEndpoint({
    required this.endpointId,
    required this.enterpriseId,
    required this.name,
    required this.targetUrl,
    required this.hmacSecret,
    this.isEnabled = true,
    this.subscribedSeverities = const [
      TerminalAlertSeverity.warning,
      TerminalAlertSeverity.critical,
    ],
  });

  Map<String, dynamic> toMap() => {
    'endpointId': endpointId,
    'enterpriseId': enterpriseId,
    'name': name,
    'targetUrl': targetUrl,
    'hmacSecret': hmacSecret,
    'isEnabled': isEnabled,
    'subscribedSeverities': subscribedSeverities.map((s) => s.name).toList(),
  };

  factory TerminalWebhookEndpoint.fromMap(Map<String, dynamic> map) {
    return TerminalWebhookEndpoint(
      endpointId: map['endpointId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      name: map['name'] as String? ?? 'Webhook Endpoint',
      targetUrl: map['targetUrl'] as String? ?? '',
      hmacSecret: map['hmacSecret'] as String? ?? '',
      isEnabled: map['isEnabled'] as bool? ?? true,
      subscribedSeverities: (map['subscribedSeverities'] as List? ?? [])
          .map((s) => TerminalAlertSeverity.values.firstWhere(
                (v) => v.name == s,
                orElse: () => TerminalAlertSeverity.critical,
              ))
          .toList(),
    );
  }
}

/// Structured outbound alert payload formatted for external webhooks
class TerminalWebhookAlertPayload {
  final String alertId;
  final String enterpriseId;
  final String terminalId;
  final String terminalName;
  final TerminalAlertEventType eventType;
  final TerminalAlertSeverity severity;
  final String message;
  final DateTime triggeredAt;
  final Map<String, dynamic> diagnostics;

  const TerminalWebhookAlertPayload({
    required this.alertId,
    required this.enterpriseId,
    required this.terminalId,
    required this.terminalName,
    required this.eventType,
    required this.severity,
    required this.message,
    required this.triggeredAt,
    this.diagnostics = const {},
  });

  Map<String, dynamic> toMap() => {
    'alertId': alertId,
    'enterpriseId': enterpriseId,
    'terminalId': terminalId,
    'terminalName': terminalName,
    'eventType': eventType.name,
    'severity': severity.name,
    'message': message,
    'triggeredAt': triggeredAt.toIso8601String(),
    'diagnostics': diagnostics,
  };

  factory TerminalWebhookAlertPayload.fromMap(Map<String, dynamic> map) {
    return TerminalWebhookAlertPayload(
      alertId: map['alertId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      terminalId: map['terminalId'] as String? ?? '',
      terminalName: map['terminalName'] as String? ?? 'Terminal',
      eventType: TerminalAlertEventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => TerminalAlertEventType.heartbeatLost,
      ),
      severity: TerminalAlertSeverity.values.firstWhere(
        (s) => s.name == map['severity'],
        orElse: () => TerminalAlertSeverity.critical,
      ),
      message: map['message'] as String? ?? '',
      triggeredAt: map['triggeredAt'] != null
          ? DateTime.tryParse(map['triggeredAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      diagnostics: Map<String, dynamic>.from(map['diagnostics'] as Map? ?? {}),
    );
  }
}
