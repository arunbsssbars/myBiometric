import 'package:flutter/foundation.dart';

/// Request model for submitting a direct local LAN punch from mobile to physical terminal
@immutable
class LocalLanMachinePunchRequest {
  final String terminalIp;
  final int port;
  final String employeeId;
  final String enterpriseId;
  final String punchType; // 'PUNCH_IN' or 'PUNCH_OUT'
  final String protocol; // 'ISAPI' or 'ADMS'
  final DateTime punchTime;
  final String? clientAuthToken;

  const LocalLanMachinePunchRequest({
    required this.terminalIp,
    this.port = 80,
    required this.employeeId,
    required this.enterpriseId,
    required this.punchType,
    this.protocol = 'ISAPI',
    required this.punchTime,
    this.clientAuthToken,
  });

  Map<String, dynamic> toMap() => {
        'terminalIp': terminalIp,
        'port': port,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'punchType': punchType,
        'protocol': protocol,
        'punchTime': punchTime.toIso8601String(),
        'clientAuthToken': clientAuthToken,
      };

  factory LocalLanMachinePunchRequest.fromMap(Map<String, dynamic> map) =>
      LocalLanMachinePunchRequest(
        terminalIp: map['terminalIp'] as String? ?? '192.168.1.100',
        port: map['port'] as int? ?? 80,
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        punchType: map['punchType'] as String? ?? 'PUNCH_IN',
        protocol: map['protocol'] as String? ?? 'ISAPI',
        punchTime: map['punchTime'] != null
            ? DateTime.tryParse(map['punchTime'] as String) ?? DateTime.now()
            : DateTime.now(),
        clientAuthToken: map['clientAuthToken'] as String?,
      );
}
