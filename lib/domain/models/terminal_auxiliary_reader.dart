/// Hardware communication protocol used by auxiliary slave readers.
enum AuxiliaryReaderProtocol {
  wiegand26, // Standard 26-bit (1 parity + 8 facility + 16 card + 1 parity)
  wiegand34, // Extended 34-bit (1 parity + 16 facility + 16 card + 1 parity)
  wiegand37, // High security 37-bit (1 parity + 19 facility + 16 card + 1 parity)
  osdpV2SecureChannel, // RS-485 OSDP v2 encrypted
}

/// Domain model representing an auxiliary slave reader attached to a physical biometric machine.
class TerminalAuxiliaryReaderConfig {
  final String id;
  final String deviceId;
  final String readerName;
  final AuxiliaryReaderProtocol protocol;
  final int facilityCode;
  final int osdpAddress; // 1 - 8 for RS-485 bus
  final String? osdpSecureChannelKey; // 128-bit AES key hex/base64
  final String direction; // 'ENTRY' or 'EXIT'
  final bool isEnabled;
  final DateTime createdAt;

  const TerminalAuxiliaryReaderConfig({
    required this.id,
    required this.deviceId,
    required this.readerName,
    this.protocol = AuxiliaryReaderProtocol.wiegand26,
    this.facilityCode = 101,
    this.osdpAddress = 1,
    this.osdpSecureChannelKey,
    this.direction = 'ENTRY',
    this.isEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'readerName': readerName,
      'protocol': protocol.name,
      'facilityCode': facilityCode,
      'osdpAddress': osdpAddress,
      'osdpSecureChannelKey': osdpSecureChannelKey,
      'direction': direction,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TerminalAuxiliaryReaderConfig.fromJson(Map<String, dynamic> json) {
    AuxiliaryReaderProtocol parseProtocol(String? name) {
      return AuxiliaryReaderProtocol.values.firstWhere(
        (p) => p.name == name,
        orElse: () => AuxiliaryReaderProtocol.wiegand26,
      );
    }

    return TerminalAuxiliaryReaderConfig(
      id: json['id'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      readerName: json['readerName'] as String? ?? 'Auxiliary Reader',
      protocol: parseProtocol(json['protocol'] as String?),
      facilityCode: (json['facilityCode'] as num?)?.toInt() ?? 101,
      osdpAddress: (json['osdpAddress'] as num?)?.toInt() ?? 1,
      osdpSecureChannelKey: json['osdpSecureChannelKey'] as String?,
      direction: json['direction'] as String? ?? 'ENTRY',
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
