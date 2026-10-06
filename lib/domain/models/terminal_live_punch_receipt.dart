import 'package:flutter/foundation.dart';

/// Instant real-time feedback event emitted by the physical terminal back to mobile phone
@immutable
class TerminalLivePunchReceipt {
  final String receiptId;
  final String terminalId;
  final String terminalDeviceName;
  final String employeeId;
  final String punchType; // 'PUNCH_IN' or 'PUNCH_OUT'
  final DateTime terminalTimestamp;
  final double faceSimilarityScore; // e.g. 0.94 (94%)
  final bool accessGranted;
  final String displayMessage; // e.g. 'Thank You, John! Access Granted.'
  final int gateRelayOpenDurationMs;

  const TerminalLivePunchReceipt({
    required this.receiptId,
    required this.terminalId,
    required this.terminalDeviceName,
    required this.employeeId,
    required this.punchType,
    required this.terminalTimestamp,
    this.faceSimilarityScore = 0.95,
    required this.accessGranted,
    required this.displayMessage,
    this.gateRelayOpenDurationMs = 3000,
  });

  Map<String, dynamic> toMap() => {
        'receiptId': receiptId,
        'terminalId': terminalId,
        'terminalDeviceName': terminalDeviceName,
        'employeeId': employeeId,
        'punchType': punchType,
        'terminalTimestamp': terminalTimestamp.toIso8601String(),
        'faceSimilarityScore': faceSimilarityScore,
        'accessGranted': accessGranted,
        'displayMessage': displayMessage,
        'gateRelayOpenDurationMs': gateRelayOpenDurationMs,
      };

  factory TerminalLivePunchReceipt.fromMap(Map<String, dynamic> map) =>
      TerminalLivePunchReceipt(
        receiptId: map['receiptId'] as String? ?? '',
        terminalId: map['terminalId'] as String? ?? '',
        terminalDeviceName: map['terminalDeviceName'] as String? ?? 'Terminal',
        employeeId: map['employeeId'] as String? ?? '',
        punchType: map['punchType'] as String? ?? 'PUNCH_IN',
        terminalTimestamp: map['terminalTimestamp'] != null
            ? DateTime.tryParse(map['terminalTimestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        faceSimilarityScore: (map['faceSimilarityScore'] as num?)?.toDouble() ?? 0.95,
        accessGranted: map['accessGranted'] as bool? ?? true,
        displayMessage: map['displayMessage'] as String? ?? 'Success',
        gateRelayOpenDurationMs: map['gateRelayOpenDurationMs'] as int? ?? 3000,
      );
}
