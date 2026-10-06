import 'package:flutter/foundation.dart';

/// Comprehensive pairing bond between mobile smartphone and physical access terminal
@immutable
class MobileTerminalPairingBond {
  final String bondId;
  final String terminalId;
  final String terminalName;
  final String employeeId;
  final String enterpriseId;
  final String publicDeviceKey;
  final bool autoPunchOnProximity;
  final int autoPunchCooldownSeconds;
  final DateTime pairedAt;
  final DateTime? lastAutoPunchedAt;

  const MobileTerminalPairingBond({
    required this.bondId,
    required this.terminalId,
    required this.terminalName,
    required this.employeeId,
    required this.enterpriseId,
    required this.publicDeviceKey,
    this.autoPunchOnProximity = true,
    this.autoPunchCooldownSeconds = 300, // 5 minutes cooldown
    required this.pairedAt,
    this.lastAutoPunchedAt,
  });

  bool canAutoPunchNow() {
    if (!autoPunchOnProximity) return false;
    if (lastAutoPunchedAt == null) return true;
    final elapsed = DateTime.now().difference(lastAutoPunchedAt!).inSeconds;
    return elapsed >= autoPunchCooldownSeconds;
  }

  Map<String, dynamic> toMap() => {
        'bondId': bondId,
        'terminalId': terminalId,
        'terminalName': terminalName,
        'employeeId': employeeId,
        'enterpriseId': enterpriseId,
        'publicDeviceKey': publicDeviceKey,
        'autoPunchOnProximity': autoPunchOnProximity,
        'autoPunchCooldownSeconds': autoPunchCooldownSeconds,
        'pairedAt': pairedAt.toIso8601String(),
        'lastAutoPunchedAt': lastAutoPunchedAt?.toIso8601String(),
      };

  factory MobileTerminalPairingBond.fromMap(Map<String, dynamic> map) =>
      MobileTerminalPairingBond(
        bondId: map['bondId'] as String? ?? '',
        terminalId: map['terminalId'] as String? ?? '',
        terminalName: map['terminalName'] as String? ?? 'Terminal',
        employeeId: map['employeeId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        publicDeviceKey: map['publicDeviceKey'] as String? ?? '',
        autoPunchOnProximity: map['autoPunchOnProximity'] as bool? ?? true,
        autoPunchCooldownSeconds: map['autoPunchCooldownSeconds'] as int? ?? 300,
        pairedAt: map['pairedAt'] != null
            ? DateTime.tryParse(map['pairedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        lastAutoPunchedAt: map['lastAutoPunchedAt'] != null
            ? DateTime.tryParse(map['lastAutoPunchedAt'] as String)
            : null,
      );
}
