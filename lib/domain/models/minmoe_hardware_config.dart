import 'package:flutter/foundation.dart';

enum MinMoeLivenessMode {
  monocularIr,
  binocularStereoDepth,
  structuredLight3d,
}

enum MinMoeAudioPrompt {
  thankYou,
  accessGranted,
  pleaseTryAgain,
  antiSpoofRejected,
  customVoiceChime,
}

/// Hardware peripheral configuration payload for Hikvision MinMoe ISAPI terminals
@immutable
class MinMoeHardwareConfig {
  final String terminalId;
  final String deviceIp;
  final int httpPort;
  final int isapiPort;
  final MinMoeLivenessMode livenessMode;
  final double faceMatchThreshold; // 0.70 to 0.99
  final int recognitionDistanceCm; // e.g. 30 to 200
  final bool whiteLightSupplementEnabled;
  final int whiteLightBrightnessPercent; // 0 to 100
  final bool irIlluminationEnabled;
  final bool maskDetectionEnabled;
  final bool feverScreeningEnabled;
  final double feverThresholdCelsius;
  final MinMoeAudioPrompt voicePrompt;
  final int volumeLevel; // 0 to 100
  final bool tamperAlarmEnabled;

  const MinMoeHardwareConfig({
    required this.terminalId,
    required this.deviceIp,
    this.httpPort = 80,
    this.isapiPort = 8000,
    this.livenessMode = MinMoeLivenessMode.binocularStereoDepth,
    this.faceMatchThreshold = 0.85,
    this.recognitionDistanceCm = 120,
    this.whiteLightSupplementEnabled = true,
    this.whiteLightBrightnessPercent = 80,
    this.irIlluminationEnabled = true,
    this.maskDetectionEnabled = false,
    this.feverScreeningEnabled = false,
    this.feverThresholdCelsius = 37.5,
    this.voicePrompt = MinMoeAudioPrompt.thankYou,
    this.volumeLevel = 75,
    this.tamperAlarmEnabled = true,
  });

  Map<String, dynamic> toMap() => {
        'terminalId': terminalId,
        'deviceIp': deviceIp,
        'httpPort': httpPort,
        'isapiPort': isapiPort,
        'livenessMode': livenessMode.name,
        'faceMatchThreshold': faceMatchThreshold,
        'recognitionDistanceCm': recognitionDistanceCm,
        'whiteLightSupplementEnabled': whiteLightSupplementEnabled,
        'whiteLightBrightnessPercent': whiteLightBrightnessPercent,
        'irIlluminationEnabled': irIlluminationEnabled,
        'maskDetectionEnabled': maskDetectionEnabled,
        'feverScreeningEnabled': feverScreeningEnabled,
        'feverThresholdCelsius': feverThresholdCelsius,
        'voicePrompt': voicePrompt.name,
        'volumeLevel': volumeLevel,
        'tamperAlarmEnabled': tamperAlarmEnabled,
      };

  factory MinMoeHardwareConfig.fromMap(Map<String, dynamic> map) =>
      MinMoeHardwareConfig(
        terminalId: map['terminalId'] as String? ?? '',
        deviceIp: map['deviceIp'] as String? ?? '',
        httpPort: (map['httpPort'] as num?)?.toInt() ?? 80,
        isapiPort: (map['isapiPort'] as num?)?.toInt() ?? 8000,
        livenessMode: MinMoeLivenessMode.values.firstWhere(
          (e) => e.name == map['livenessMode'],
          orElse: () => MinMoeLivenessMode.binocularStereoDepth,
        ),
        faceMatchThreshold: (map['faceMatchThreshold'] as num?)?.toDouble() ?? 0.85,
        recognitionDistanceCm: (map['recognitionDistanceCm'] as num?)?.toInt() ?? 120,
        whiteLightSupplementEnabled: map['whiteLightSupplementEnabled'] as bool? ?? true,
        whiteLightBrightnessPercent: (map['whiteLightBrightnessPercent'] as num?)?.toInt() ?? 80,
        irIlluminationEnabled: map['irIlluminationEnabled'] as bool? ?? true,
        maskDetectionEnabled: map['maskDetectionEnabled'] as bool? ?? false,
        feverScreeningEnabled: map['feverScreeningEnabled'] as bool? ?? false,
        feverThresholdCelsius: (map['feverThresholdCelsius'] as num?)?.toDouble() ?? 37.5,
        voicePrompt: MinMoeAudioPrompt.values.firstWhere(
          (e) => e.name == map['voicePrompt'],
          orElse: () => MinMoeAudioPrompt.thankYou,
        ),
        volumeLevel: (map['volumeLevel'] as num?)?.toInt() ?? 75,
        tamperAlarmEnabled: map['tamperAlarmEnabled'] as bool? ?? true,
      );
}
