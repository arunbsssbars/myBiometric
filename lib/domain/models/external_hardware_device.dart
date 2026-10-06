
/// Supported external timeclock hardware vendors.
enum TimeclockVendor {
  zkteco,
  hikvision,
  anviz,
  suprema,
  dahua,
  genericOnvif,
}

/// Represents the status of an external biometric reader or terminal.
enum DeviceHealthStatus {
  online,
  offline,
  degraded,
  tampered,
  synchronizing,
}

/// Verification factor utilized during an external terminal punch.
enum HardwareVerificationMethod {
  face3D,
  fingerprintOptical,
  rfidMifare,
  palmVein,
  pinCode,
  qrCodeDynamic,
  bleBeaconProximity,
}

/// Enterprise Model representing a physical biometric machine deployed on-premise or cloud.
class ExternalHardwareDevice {
  final String deviceId;
  final String enterpriseId;
  final String deviceName;
  final String ipAddress;
  final int port;
  final TimeclockVendor vendor;
  final String serialNumber;
  final String firmwareVersion;
  final String locationTag;
  final DeviceHealthStatus status;
  final DateTime lastHeartbeat;
  final int pendingLogsCount;
  final bool isRelayTriggerEnabled;
  final List<HardwareVerificationMethod> supportedMethods;
  final Map<String, dynamic> metadata;

  const ExternalHardwareDevice({
    required this.deviceId,
    required this.enterpriseId,
    required this.deviceName,
    required this.ipAddress,
    this.port = 4370,
    required this.vendor,
    required this.serialNumber,
    this.firmwareVersion = '1.0.0',
    this.locationTag = 'Main Gate',
    this.status = DeviceHealthStatus.online,
    required this.lastHeartbeat,
    this.pendingLogsCount = 0,
    this.isRelayTriggerEnabled = true,
    this.supportedMethods = const [
      HardwareVerificationMethod.face3D,
      HardwareVerificationMethod.fingerprintOptical,
      HardwareVerificationMethod.rfidMifare,
    ],
    this.metadata = const {},
  });

  bool get isHealthy =>
      status == DeviceHealthStatus.online &&
      DateTime.now().difference(lastHeartbeat).inMinutes < 15;

  bool get requiresFirmwareUpdate =>
      firmwareVersion.startsWith('0.') || firmwareVersion == '1.0.0-beta';

  ExternalHardwareDevice copyWith({
    String? deviceId,
    String? enterpriseId,
    String? deviceName,
    String? ipAddress,
    int? port,
    TimeclockVendor? vendor,
    String? serialNumber,
    String? firmwareVersion,
    String? locationTag,
    DeviceHealthStatus? status,
    DateTime? lastHeartbeat,
    int? pendingLogsCount,
    bool? isRelayTriggerEnabled,
    List<HardwareVerificationMethod>? supportedMethods,
    Map<String, dynamic>? metadata,
  }) {
    return ExternalHardwareDevice(
      deviceId: deviceId ?? this.deviceId,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      vendor: vendor ?? this.vendor,
      serialNumber: serialNumber ?? this.serialNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      locationTag: locationTag ?? this.locationTag,
      status: status ?? this.status,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      pendingLogsCount: pendingLogsCount ?? this.pendingLogsCount,
      isRelayTriggerEnabled:
          isRelayTriggerEnabled ?? this.isRelayTriggerEnabled,
      supportedMethods: supportedMethods ?? this.supportedMethods,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'enterpriseId': enterpriseId,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'port': port,
      'vendor': vendor.name,
      'serialNumber': serialNumber,
      'firmwareVersion': firmwareVersion,
      'locationTag': locationTag,
      'status': status.name,
      'lastHeartbeat': lastHeartbeat.toIso8601String(),
      'pendingLogsCount': pendingLogsCount,
      'isRelayTriggerEnabled': isRelayTriggerEnabled,
      'supportedMethods': supportedMethods.map((m) => m.name).toList(),
      'metadata': metadata,
    };
  }

  factory ExternalHardwareDevice.fromMap(Map<String, dynamic> map) {
    return ExternalHardwareDevice(
      deviceId: map['deviceId'] as String? ?? '',
      enterpriseId: map['enterpriseId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? 'Biometric Device',
      ipAddress: map['ipAddress'] as String? ?? '127.0.0.1',
      port: map['port'] as int? ?? 4370,
      vendor: TimeclockVendor.values.firstWhere(
        (v) => v.name == map['vendor'],
        orElse: () => TimeclockVendor.zkteco,
      ),
      serialNumber: map['serialNumber'] as String? ?? 'UNKNOWN-SN',
      firmwareVersion: map['firmwareVersion'] as String? ?? '1.0.0',
      locationTag: map['locationTag'] as String? ?? 'Default Zone',
      status: DeviceHealthStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DeviceHealthStatus.offline,
      ),
      lastHeartbeat: map['lastHeartbeat'] != null
          ? DateTime.tryParse(map['lastHeartbeat'].toString()) ?? DateTime.now()
          : DateTime.now(),
      pendingLogsCount: map['pendingLogsCount'] as int? ?? 0,
      isRelayTriggerEnabled: map['isRelayTriggerEnabled'] as bool? ?? true,
      supportedMethods: (map['supportedMethods'] as List<dynamic>?)
              ?.map((item) => HardwareVerificationMethod.values.firstWhere(
                    (m) => m.name == item,
                    orElse: () => HardwareVerificationMethod.rfidMifare,
                  ))
              .toList() ??
          const [
            HardwareVerificationMethod.face3D,
            HardwareVerificationMethod.fingerprintOptical,
          ],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }
}
