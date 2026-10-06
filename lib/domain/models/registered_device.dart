import 'package:flutter/foundation.dart';

enum DevicePlatformType {
  android,
  ios,
  web,
  windows,
  macos,
  linux,
}

enum DeviceTrustStatus {
  trusted,
  pendingVerification,
  suspended,
  quarantined,
}

/// Domain model representing an employee's registered hardware device
@immutable
class RegisteredDevice {
  final String deviceId;
  final String userId;
  final String enterpriseId;
  final String deviceName;
  final String model;
  final DevicePlatformType platform;
  final String osVersion;
  final String appVersion;
  final DeviceTrustStatus status;
  final String deviceFingerprintSha256;
  final DateTime enrolledAt;
  final DateTime lastActiveAt;
  final bool isJailbrokenOrRooted;
  final String? ipAddress;

  const RegisteredDevice({
    required this.deviceId,
    required this.userId,
    required this.enterpriseId,
    required this.deviceName,
    required this.model,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.status,
    required this.deviceFingerprintSha256,
    required this.enrolledAt,
    required this.lastActiveAt,
    this.isJailbrokenOrRooted = false,
    this.ipAddress,
  });

  bool get isAllowedToPunch =>
      status == DeviceTrustStatus.trusted && !isJailbrokenOrRooted;

  RegisteredDevice copyWith({
    String? deviceId,
    String? userId,
    String? enterpriseId,
    String? deviceName,
    String? model,
    DevicePlatformType? platform,
    String? osVersion,
    String? appVersion,
    DeviceTrustStatus? status,
    String? deviceFingerprintSha256,
    DateTime? enrolledAt,
    DateTime? lastActiveAt,
    bool? isJailbrokenOrRooted,
    String? ipAddress,
  }) {
    return RegisteredDevice(
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      deviceName: deviceName ?? this.deviceName,
      model: model ?? this.model,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      status: status ?? this.status,
      deviceFingerprintSha256:
          deviceFingerprintSha256 ?? this.deviceFingerprintSha256,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isJailbrokenOrRooted: isJailbrokenOrRooted ?? this.isJailbrokenOrRooted,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'userId': userId,
      'enterpriseId': enterpriseId,
      'deviceName': deviceName,
      'model': model,
      'platform': platform.name,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'status': status.name,
      'deviceFingerprintSha256': deviceFingerprintSha256,
      'enrolledAt': enrolledAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isJailbrokenOrRooted': isJailbrokenOrRooted,
      'ipAddress': ipAddress,
    };
  }

  factory RegisteredDevice.fromMap(Map<String, dynamic> map) {
    return RegisteredDevice(
      deviceId: map['deviceId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? 'Unknown Device',
      model: map['model'] as String? ?? 'Generic',
      platform: DevicePlatformType.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => DevicePlatformType.android,
      ),
      osVersion: map['osVersion'] as String? ?? 'N/A',
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      status: DeviceTrustStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DeviceTrustStatus.pendingVerification,
      ),
      deviceFingerprintSha256: map['deviceFingerprintSha256'] as String? ?? '',
      enrolledAt: map['enrolledAt'] != null
          ? DateTime.tryParse(map['enrolledAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isJailbrokenOrRooted: map['isJailbrokenOrRooted'] as bool? ?? false,
      ipAddress: map['ipAddress'] as String?,
    );
  }
}
