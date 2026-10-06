/// Protocol supported by external biometric hardware machines.
enum TerminalProtocol {
  hikvisionIsapi,
  hikvisionIsupPush,
  zkTecoAdms,
  dahuaHttp,
  supremaBioStar,
  genericWebhook,
}

/// Physical or network connection status of the biometric terminal.
enum DeviceConnectionStatus {
  online,
  offline,
  syncing,
  error,
  unregistered,
}

/// Primary authentication mode used on the physical terminal.
enum DeviceAuthMode {
  face,
  fingerprint,
  card,
  pin,
  multiModal,
}

/// Domain model representing an external physical biometric machine (Hikvision MinMoe, ZKTeco, etc.)
class BiometricTerminalDevice {
  final String id;
  final String enterpriseId;
  final String name;
  final String? serialNumber;
  final String modelName; // e.g. "DS-K1T343EFWX", "DS-K1T343MWX", "FaceDepot-7B"
  final TerminalProtocol protocol;
  final String ipAddress;
  final int port;
  final String? username;
  final String? password; // Stored securely/encrypted
  final String? branchId;
  final String? branchName;
  final DeviceConnectionStatus status;
  final DateTime? lastHeartbeatAt;
  final DateTime? lastSyncAt;
  final int totalEventsSynced;
  final bool autoSyncEnabled;
  final int syncIntervalMinutes;
  final Map<String, dynamic> customConfig;
  final DateTime createdAt;

  const BiometricTerminalDevice({
    required this.id,
    required this.enterpriseId,
    required this.name,
    this.serialNumber,
    required this.modelName,
    required this.protocol,
    required this.ipAddress,
    this.port = 80,
    this.username,
    this.password,
    this.branchId,
    this.branchName,
    this.status = DeviceConnectionStatus.offline,
    this.lastHeartbeatAt,
    this.lastSyncAt,
    this.totalEventsSynced = 0,
    this.autoSyncEnabled = true,
    this.syncIntervalMinutes = 15,
    this.customConfig = const {},
    required this.createdAt,
  });

  String get protocolDisplayName {
    switch (protocol) {
      case TerminalProtocol.hikvisionIsapi:
        return 'Hikvision ISAPI';
      case TerminalProtocol.hikvisionIsupPush:
        return 'Hikvision ISUP 5.0 (EHome)';
      case TerminalProtocol.zkTecoAdms:
        return 'ZKTeco ADMS / Push';
      case TerminalProtocol.dahuaHttp:
        return 'Dahua HTTP API';
      case TerminalProtocol.supremaBioStar:
        return 'Suprema BioStar API';
      case TerminalProtocol.genericWebhook:
        return 'Cloud Webhook / REST';
    }
  }

  bool get isOnline => status == DeviceConnectionStatus.online;

  BiometricTerminalDevice copyWith({
    String? id,
    String? enterpriseId,
    String? name,
    String? serialNumber,
    String? modelName,
    TerminalProtocol? protocol,
    String? ipAddress,
    int? port,
    String? username,
    String? password,
    String? branchId,
    String? branchName,
    DeviceConnectionStatus? status,
    DateTime? lastHeartbeatAt,
    DateTime? lastSyncAt,
    int? totalEventsSynced,
    bool? autoSyncEnabled,
    int? syncIntervalMinutes,
    Map<String, dynamic>? customConfig,
    DateTime? createdAt,
  }) {
    return BiometricTerminalDevice(
      id: id ?? this.id,
      enterpriseId: enterpriseId ?? this.enterpriseId,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      modelName: modelName ?? this.modelName,
      protocol: protocol ?? this.protocol,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      status: status ?? this.status,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      totalEventsSynced: totalEventsSynced ?? this.totalEventsSynced,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      customConfig: customConfig ?? this.customConfig,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enterpriseId': enterpriseId,
      'name': name,
      if (serialNumber != null) 'serialNumber': serialNumber,
      'modelName': modelName,
      'protocol': protocol.name,
      'ipAddress': ipAddress,
      'port': port,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (branchId != null) 'branchId': branchId,
      if (branchName != null) 'branchName': branchName,
      'status': status.name,
      if (lastHeartbeatAt != null) 'lastHeartbeatAt': lastHeartbeatAt!.toIso8601String(),
      if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.toIso8601String(),
      'totalEventsSynced': totalEventsSynced,
      'autoSyncEnabled': autoSyncEnabled,
      'syncIntervalMinutes': syncIntervalMinutes,
      'customConfig': customConfig,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BiometricTerminalDevice.fromMap(Map<String, dynamic> map, {String? id}) {
    return BiometricTerminalDevice(
      id: id ?? map['id']?.toString() ?? '',
      enterpriseId: map['enterpriseId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Biometric Terminal',
      serialNumber: map['serialNumber']?.toString(),
      modelName: map['modelName']?.toString() ?? 'Hikvision MinMoe',
      protocol: TerminalProtocol.values.firstWhere(
        (e) => e.name == map['protocol'],
        orElse: () => TerminalProtocol.hikvisionIsapi,
      ),
      ipAddress: map['ipAddress']?.toString() ?? '192.168.1.100',
      port: (map['port'] as num?)?.toInt() ?? 80,
      username: map['username']?.toString(),
      password: map['password']?.toString(),
      branchId: map['branchId']?.toString(),
      branchName: map['branchName']?.toString(),
      status: DeviceConnectionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DeviceConnectionStatus.offline,
      ),
      lastHeartbeatAt: map['lastHeartbeatAt'] != null
          ? DateTime.tryParse(map['lastHeartbeatAt'].toString())
          : null,
      lastSyncAt: map['lastSyncAt'] != null
          ? DateTime.tryParse(map['lastSyncAt'].toString())
          : null,
      totalEventsSynced: (map['totalEventsSynced'] as num?)?.toInt() ?? 0,
      autoSyncEnabled: map['autoSyncEnabled'] as bool? ?? true,
      syncIntervalMinutes: (map['syncIntervalMinutes'] as num?)?.toInt() ?? 15,
      customConfig: (map['customConfig'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Raw or normalized attendance punch received from an external biometric terminal.
class TerminalAttendanceEvent {
  final String eventId;
  final String deviceId;
  final String employeeId;
  final String? employeeName;
  final DateTime timestamp;
  final String punchType; // "PUNCH_IN", "PUNCH_OUT", "START_BREAK", "END_BREAK"
  final DeviceAuthMode authMode; // face, fingerprint, card, pin
  final String? cardNo;
  final double? similarityScore;
  final String? rawPayload;
  final bool isProcessed;

  const TerminalAttendanceEvent({
    required this.eventId,
    required this.deviceId,
    required this.employeeId,
    this.employeeName,
    required this.timestamp,
    required this.punchType,
    this.authMode = DeviceAuthMode.face,
    this.cardNo,
    this.similarityScore,
    this.rawPayload,
    this.isProcessed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'deviceId': deviceId,
      'employeeId': employeeId,
      if (employeeName != null) 'employeeName': employeeName,
      'timestamp': timestamp.toIso8601String(),
      'punchType': punchType,
      'authMode': authMode.name,
      if (cardNo != null) 'cardNo': cardNo,
      if (similarityScore != null) 'similarityScore': similarityScore,
      if (rawPayload != null) 'rawPayload': rawPayload,
      'isProcessed': isProcessed,
    };
  }

  bool get isDoorUnlocked => isProcessed || punchType == 'PUNCH_IN' || punchType == 'PUNCH_OUT';

  Map<String, dynamic> toJson() => toMap();

  factory TerminalAttendanceEvent.fromMap(Map<String, dynamic> map) {
    return TerminalAttendanceEvent(
      eventId: map['eventId']?.toString() ?? '',
      deviceId: map['deviceId']?.toString() ?? '',
      employeeId: map['employeeId']?.toString() ?? '',
      employeeName: map['employeeName']?.toString(),
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      punchType: map['punchType']?.toString() ?? 'PUNCH_IN',
      authMode: DeviceAuthMode.values.firstWhere(
        (e) => e.name == map['authMode'],
        orElse: () => DeviceAuthMode.face,
      ),
      cardNo: map['cardNo']?.toString(),
      similarityScore: (map['similarityScore'] as num?)?.toDouble(),
      rawPayload: map['rawPayload']?.toString(),
      isProcessed: map['isProcessed'] as bool? ?? false,
    );
  }

  factory TerminalAttendanceEvent.fromJson(Map<String, dynamic> json) =>
      TerminalAttendanceEvent.fromMap(json);
}
