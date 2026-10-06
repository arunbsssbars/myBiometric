import 'package:flutter/foundation.dart';

enum ZkPushCommunicationType {
  admsHttp,
  iclockHttps,
  cloudServerPoll,
}

/// ZKTeco ADMS / IClock machine communication and table synchronization profile
@immutable
class ZktecoAdmsProfile {
  final String deviceSerialNumber;
  final String deviceIp;
  final int pushPort;
  final ZkPushCommunicationType protocol;
  final int heartbeatIntervalSeconds;
  final int delayLogTransmissionSeconds;
  final String serverUrl;
  final bool realTimePushEnabled;
  final bool biometricTemplateSyncEnabled;
  final int timezoneOffsetMinutes;
  final String firmwareVersion;
  final String languageCode;

  const ZktecoAdmsProfile({
    required this.deviceSerialNumber,
    required this.deviceIp,
    this.pushPort = 8088,
    this.protocol = ZkPushCommunicationType.admsHttp,
    this.heartbeatIntervalSeconds = 60,
    this.delayLogTransmissionSeconds = 0,
    required this.serverUrl,
    this.realTimePushEnabled = true,
    this.biometricTemplateSyncEnabled = true,
    this.timezoneOffsetMinutes = 330, // Default IST UTC+5:30
    this.firmwareVersion = 'Ver 8.2.4',
    this.languageCode = 'en',
  });

  Map<String, dynamic> toMap() => {
        'deviceSerialNumber': deviceSerialNumber,
        'deviceIp': deviceIp,
        'pushPort': pushPort,
        'protocol': protocol.name,
        'heartbeatIntervalSeconds': heartbeatIntervalSeconds,
        'delayLogTransmissionSeconds': delayLogTransmissionSeconds,
        'serverUrl': serverUrl,
        'realTimePushEnabled': realTimePushEnabled,
        'biometricTemplateSyncEnabled': biometricTemplateSyncEnabled,
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
        'firmwareVersion': firmwareVersion,
        'languageCode': languageCode,
      };

  factory ZktecoAdmsProfile.fromMap(Map<String, dynamic> map) =>
      ZktecoAdmsProfile(
        deviceSerialNumber: map['deviceSerialNumber'] as String? ?? '',
        deviceIp: map['deviceIp'] as String? ?? '',
        pushPort: (map['pushPort'] as num?)?.toInt() ?? 8088,
        protocol: ZkPushCommunicationType.values.firstWhere(
          (e) => e.name == map['protocol'],
          orElse: () => ZkPushCommunicationType.admsHttp,
        ),
        heartbeatIntervalSeconds: (map['heartbeatIntervalSeconds'] as num?)?.toInt() ?? 60,
        delayLogTransmissionSeconds: (map['delayLogTransmissionSeconds'] as num?)?.toInt() ?? 0,
        serverUrl: map['serverUrl'] as String? ?? 'http://push.server.corp',
        realTimePushEnabled: map['realTimePushEnabled'] as bool? ?? true,
        biometricTemplateSyncEnabled: map['biometricTemplateSyncEnabled'] as bool? ?? true,
        timezoneOffsetMinutes: (map['timezoneOffsetMinutes'] as num?)?.toInt() ?? 330,
        firmwareVersion: map['firmwareVersion'] as String? ?? 'Ver 8.2.4',
        languageCode: map['languageCode'] as String? ?? 'en',
      );
}
