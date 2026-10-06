import 'package:flutter/foundation.dart';

enum ZkDeviceCommandStatus {
  queued,
  sent,
  executedSuccess,
  executedFailed,
}

/// Remote command sent to ZKTeco machine via ADMS polling queue
@immutable
class ZktecoMachineCommand {
  final int commandId;
  final String deviceSerialNumber;
  final String commandString; // e.g., 'CHECK', 'INFO', 'REBOOT', 'CLEAR LOG', 'CLEAR DATA'
  final ZkDeviceCommandStatus status;
  final DateTime createdAt;
  final DateTime? executedAt;
  final String? returnCode; // e.g. '0', '-1'

  const ZktecoMachineCommand({
    required this.commandId,
    required this.deviceSerialNumber,
    required this.commandString,
    this.status = ZkDeviceCommandStatus.queued,
    required this.createdAt,
    this.executedAt,
    this.returnCode,
  });

  Map<String, dynamic> toMap() => {
        'commandId': commandId,
        'deviceSerialNumber': deviceSerialNumber,
        'commandString': commandString,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'executedAt': executedAt?.toIso8601String(),
        'returnCode': returnCode,
      };

  factory ZktecoMachineCommand.fromMap(Map<String, dynamic> map) =>
      ZktecoMachineCommand(
        commandId: (map['commandId'] as num?)?.toInt() ?? 0,
        deviceSerialNumber: map['deviceSerialNumber'] as String? ?? '',
        commandString: map['commandString'] as String? ?? 'CHECK',
        status: ZkDeviceCommandStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => ZkDeviceCommandStatus.queued,
        ),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        executedAt: map['executedAt'] != null
            ? DateTime.tryParse(map['executedAt'] as String)
            : null,
        returnCode: map['returnCode'] as String?,
      );
}
