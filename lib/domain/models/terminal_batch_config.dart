/// Configuration parameters applied across a fleet of biometric hardware terminals.
class TerminalBatchConfig {
  final String ntpServerUrl;
  final int ntpPort;
  final int faceMatchThreshold; // 80 - 99%
  final String antiSpoofingLevel; // 'HIGH', 'MEDIUM', 'LOW', 'DISABLED'
  final String osdBannerText;
  final int doorOpenDurationSeconds; // 1 - 10 seconds
  final String? autoRebootDailyTime; // e.g. '03:00'
  final bool enableBuzzerOnMatch;
  final bool enableVoicePromptOnMatch;

  const TerminalBatchConfig({
    this.ntpServerUrl = 'time.google.com',
    this.ntpPort = 123,
    this.faceMatchThreshold = 90,
    this.antiSpoofingLevel = 'HIGH',
    this.osdBannerText = 'Welcome to Office',
    this.doorOpenDurationSeconds = 5,
    this.autoRebootDailyTime = '03:00',
    this.enableBuzzerOnMatch = true,
    this.enableVoicePromptOnMatch = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'ntpServerUrl': ntpServerUrl,
      'ntpPort': ntpPort,
      'faceMatchThreshold': faceMatchThreshold,
      'antiSpoofingLevel': antiSpoofingLevel,
      'osdBannerText': osdBannerText,
      'doorOpenDurationSeconds': doorOpenDurationSeconds,
      'autoRebootDailyTime': autoRebootDailyTime,
      'enableBuzzerOnMatch': enableBuzzerOnMatch,
      'enableVoicePromptOnMatch': enableVoicePromptOnMatch,
    };
  }

  factory TerminalBatchConfig.fromJson(Map<String, dynamic> json) {
    return TerminalBatchConfig(
      ntpServerUrl: json['ntpServerUrl'] as String? ?? 'time.google.com',
      ntpPort: (json['ntpPort'] as num?)?.toInt() ?? 123,
      faceMatchThreshold: (json['faceMatchThreshold'] as num?)?.toInt() ?? 90,
      antiSpoofingLevel: json['antiSpoofingLevel'] as String? ?? 'HIGH',
      osdBannerText: json['osdBannerText'] as String? ?? 'Welcome to Office',
      doorOpenDurationSeconds: (json['doorOpenDurationSeconds'] as num?)?.toInt() ?? 5,
      autoRebootDailyTime: json['autoRebootDailyTime'] as String? ?? '03:00',
      enableBuzzerOnMatch: json['enableBuzzerOnMatch'] as bool? ?? true,
      enableVoicePromptOnMatch: json['enableVoicePromptOnMatch'] as bool? ?? true,
    );
  }
}

/// Firmware release package for remote terminal OTA upgrades.
class TerminalFirmwarePackage {
  final String version;
  final String modelFamily; // e.g. 'MinMoe_DS-K1T343', 'ZKTeco_SpeedFace'
  final String binaryUrl;
  final String checksumSha256;
  final String releaseNotes;
  final DateTime publishedAt;

  const TerminalFirmwarePackage({
    required this.version,
    required this.modelFamily,
    required this.binaryUrl,
    required this.checksumSha256,
    required this.releaseNotes,
    required this.publishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'modelFamily': modelFamily,
      'binaryUrl': binaryUrl,
      'checksumSha256': checksumSha256,
      'releaseNotes': releaseNotes,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }

  factory TerminalFirmwarePackage.fromJson(Map<String, dynamic> json) {
    return TerminalFirmwarePackage(
      version: json['version'] as String? ?? '1.0.0',
      modelFamily: json['modelFamily'] as String? ?? 'Generic',
      binaryUrl: json['binaryUrl'] as String? ?? '',
      checksumSha256: json['checksumSha256'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
