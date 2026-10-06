import 'package:flutter/foundation.dart';

enum MinMoeRelayAction {
  openDoor,
  closeDoor,
  lockAlways,
  unlockAlways,
  triggerDuressAlarm,
}

/// Remote command dispatch payload for Hikvision MinMoe ISAPI access relay and I/O lines
@immutable
class MinMoeRemoteRelayCommand {
  final String terminalId;
  final int doorNo;
  final MinMoeRelayAction action;
  final int holdOpenSeconds;
  final String operatorUserId;
  final String? operatorNote;
  final DateTime issuedAt;

  const MinMoeRemoteRelayCommand({
    required this.terminalId,
    this.doorNo = 1,
    required this.action,
    this.holdOpenSeconds = 5,
    required this.operatorUserId,
    this.operatorNote,
    required this.issuedAt,
  });

  Map<String, dynamic> toMap() => {
        'terminalId': terminalId,
        'doorNo': doorNo,
        'action': action.name,
        'holdOpenSeconds': holdOpenSeconds,
        'operatorUserId': operatorUserId,
        'operatorNote': operatorNote,
        'issuedAt': issuedAt.toIso8601String(),
      };

  factory MinMoeRemoteRelayCommand.fromMap(Map<String, dynamic> map) =>
      MinMoeRemoteRelayCommand(
        terminalId: map['terminalId'] as String? ?? '',
        doorNo: (map['doorNo'] as num?)?.toInt() ?? 1,
        action: MinMoeRelayAction.values.firstWhere(
          (e) => e.name == map['action'],
          orElse: () => MinMoeRelayAction.openDoor,
        ),
        holdOpenSeconds: (map['holdOpenSeconds'] as num?)?.toInt() ?? 5,
        operatorUserId: map['operatorUserId'] as String? ?? '',
        operatorNote: map['operatorNote'] as String?,
        issuedAt: map['issuedAt'] != null
            ? DateTime.tryParse(map['issuedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
