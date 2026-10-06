import 'package:flutter/foundation.dart';

/// Comprehensive multi-terminal state controller on mobile app
@immutable
class MultiTerminalPunchSession {
  final String activeTerminalId;
  final String activeTerminalName;
  final String connectionType; // 'BLE', 'NFC', 'WIFI_LAN', 'CAMERA_QR'
  final bool isPunching;
  final String? lastPunchFeedback;
  final DateTime lastActionTime;

  const MultiTerminalPunchSession({
    required this.activeTerminalId,
    required this.activeTerminalName,
    required this.connectionType,
    this.isPunching = false,
    this.lastPunchFeedback,
    required this.lastActionTime,
  });

  MultiTerminalPunchSession copyWith({
    String? activeTerminalId,
    String? activeTerminalName,
    String? connectionType,
    bool? isPunching,
    String? lastPunchFeedback,
  }) {
    return MultiTerminalPunchSession(
      activeTerminalId: activeTerminalId ?? this.activeTerminalId,
      activeTerminalName: activeTerminalName ?? this.activeTerminalName,
      connectionType: connectionType ?? this.connectionType,
      isPunching: isPunching ?? this.isPunching,
      lastPunchFeedback: lastPunchFeedback ?? this.lastPunchFeedback,
      lastActionTime: DateTime.now(),
    );
  }
}
