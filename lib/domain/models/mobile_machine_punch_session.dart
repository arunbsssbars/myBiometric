import 'package:flutter/foundation.dart';

/// Available physical machine punch interaction channels
enum MobileMachinePunchChannel {
  opticalQr,
  bleBeacon,
  nfcVirtualBadge,
  localLanWifi,
  remoteRelay,
  keypadTotp,
  ultrasonicChirp,
}

/// Orchestration state for mobile-to-machine punches
@immutable
class MobileMachinePunchSession {
  final String sessionId;
  final String employeeId;
  final String enterpriseId;
  final MobileMachinePunchChannel activeChannel;
  final bool isReady;
  final DateTime initializedAt;

  const MobileMachinePunchSession({
    required this.sessionId,
    required this.employeeId,
    required this.enterpriseId,
    required this.activeChannel,
    this.isReady = true,
    required this.initializedAt,
  });

  MobileMachinePunchSession copyWith({
    MobileMachinePunchChannel? activeChannel,
    bool? isReady,
  }) {
    return MobileMachinePunchSession(
      sessionId: sessionId,
      employeeId: employeeId,
      enterpriseId: enterpriseId,
      activeChannel: activeChannel ?? this.activeChannel,
      isReady: isReady ?? this.isReady,
      initializedAt: initializedAt,
    );
  }
}
