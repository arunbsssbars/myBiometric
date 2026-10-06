/// Types of remote control commands dispatched to external biometric hardware machines.
enum TerminalRemoteCommandType {
  openDoor,       // Pulse relay (5 seconds standard unlock)
  closeDoor,      // Restore relay to secure state
  alwaysOpen,     // Emergency hold open / free passage mode
  alwaysClose,    // Lockdown mode
  reboot,         // Hardware soft reboot
  triggerBuzzer,  // Auditory warning chime
  voicePrompt,    // Play synthesized voice ("Thank you", "Access Granted", etc.)
}

/// Result payload returned from executing a remote hardware command on a biometric terminal.
class TerminalRemoteCommandResult {
  final bool success;
  final TerminalRemoteCommandType commandType;
  final String deviceId;
  final String deviceName;
  final int statusCode;
  final String statusString;
  final String? subStatusCode;
  final DateTime executedAt;
  final Map<String, dynamic> rawResponse;

  const TerminalRemoteCommandResult({
    required this.success,
    required this.commandType,
    required this.deviceId,
    required this.deviceName,
    required this.statusCode,
    required this.statusString,
    this.subStatusCode,
    required this.executedAt,
    this.rawResponse = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'commandType': commandType.name,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'statusCode': statusCode,
      'statusString': statusString,
      'subStatusCode': subStatusCode,
      'executedAt': executedAt.toIso8601String(),
      'rawResponse': rawResponse,
    };
  }

  factory TerminalRemoteCommandResult.fromJson(Map<String, dynamic> json) {
    TerminalRemoteCommandType parseCommandType(String? name) {
      return TerminalRemoteCommandType.values.firstWhere(
        (c) => c.name == name,
        orElse: () => TerminalRemoteCommandType.openDoor,
      );
    }

    return TerminalRemoteCommandResult(
      success: json['success'] as bool? ?? false,
      commandType: parseCommandType(json['commandType'] as String?),
      deviceId: json['deviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? 'Terminal',
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
      statusString: json['statusString'] as String? ?? 'OK',
      subStatusCode: json['subStatusCode'] as String?,
      executedAt: json['executedAt'] != null
          ? DateTime.tryParse(json['executedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      rawResponse: (json['rawResponse'] as Map<String, dynamic>?) ?? {},
    );
  }
}
