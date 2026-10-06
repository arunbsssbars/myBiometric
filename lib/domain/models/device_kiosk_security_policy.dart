import 'package:flutter/foundation.dart';

enum DeviceKioskPolicyMode {
  strictKiosk,
  autonomousSingleApp,
  supervisedWorkProfile,
}

/// Enforced lock-down security policy for unattended front-desk kiosk terminals
@immutable
class DeviceKioskSecurityPolicy {
  final String policyId;
  final String enterpriseId;
  final DeviceKioskPolicyMode mode;
  final bool disableStatusBar;
  final bool disableHomeButton;
  final bool disablePowerMenu;
  final bool disableAppSwitching;
  final bool enableUsbAccessoryBlacklist;
  final bool autoRelaunchOnCrash;
  final int screensaverTimeoutSeconds;
  final String adminEscapeSequenceSha256;

  const DeviceKioskSecurityPolicy({
    required this.policyId,
    required this.enterpriseId,
    this.mode = DeviceKioskPolicyMode.strictKiosk,
    this.disableStatusBar = true,
    this.disableHomeButton = true,
    this.disablePowerMenu = true,
    this.disableAppSwitching = true,
    this.enableUsbAccessoryBlacklist = true,
    this.autoRelaunchOnCrash = true,
    this.screensaverTimeoutSeconds = 120,
    required this.adminEscapeSequenceSha256,
  });

  Map<String, dynamic> toMap() => {
        'policyId': policyId,
        'enterpriseId': enterpriseId,
        'mode': mode.name,
        'disableStatusBar': disableStatusBar,
        'disableHomeButton': disableHomeButton,
        'disablePowerMenu': disablePowerMenu,
        'disableAppSwitching': disableAppSwitching,
        'enableUsbAccessoryBlacklist': enableUsbAccessoryBlacklist,
        'autoRelaunchOnCrash': autoRelaunchOnCrash,
        'screensaverTimeoutSeconds': screensaverTimeoutSeconds,
        'adminEscapeSequenceSha256': adminEscapeSequenceSha256,
      };

  factory DeviceKioskSecurityPolicy.fromMap(Map<String, dynamic> map) =>
      DeviceKioskSecurityPolicy(
        policyId: map['policyId'] as String? ?? '',
        enterpriseId: map['enterpriseId'] as String? ?? '',
        mode: DeviceKioskPolicyMode.values.firstWhere(
          (e) => e.name == map['mode'],
          orElse: () => DeviceKioskPolicyMode.strictKiosk,
        ),
        disableStatusBar: map['disableStatusBar'] as bool? ?? true,
        disableHomeButton: map['disableHomeButton'] as bool? ?? true,
        disablePowerMenu: map['disablePowerMenu'] as bool? ?? true,
        disableAppSwitching: map['disableAppSwitching'] as bool? ?? true,
        enableUsbAccessoryBlacklist: map['enableUsbAccessoryBlacklist'] as bool? ?? true,
        autoRelaunchOnCrash: map['autoRelaunchOnCrash'] as bool? ?? true,
        screensaverTimeoutSeconds: (map['screensaverTimeoutSeconds'] as num?)?.toInt() ?? 120,
        adminEscapeSequenceSha256: map['adminEscapeSequenceSha256'] as String? ?? '',
      );
}
