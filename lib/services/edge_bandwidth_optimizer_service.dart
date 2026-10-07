import 'dart:convert';

enum NetworkSyncMode {
  unmeteredLan,
  meteredCellular,
  offlineBatch,
}

class BandwidthQuotaConfig {
  final String deviceId;
  final double monthlyLimitMb; // e.g. 500.0 MB
  final double currentUsageMb;
  final bool compressionEnabled;
  final NetworkSyncMode syncMode;

  const BandwidthQuotaConfig({
    required this.deviceId,
    this.monthlyLimitMb = 500.0,
    this.currentUsageMb = 0.0,
    this.compressionEnabled = true,
    this.syncMode = NetworkSyncMode.unmeteredLan,
  });

  bool get isQuotaExceeded => currentUsageMb >= monthlyLimitMb;

  double get quotaUsagePercentage =>
      monthlyLimitMb <= 0 ? 0.0 : (currentUsageMb / monthlyLimitMb).clamp(0.0, 1.0);

  BandwidthQuotaConfig copyWith({
    double? currentUsageMb,
    bool? compressionEnabled,
    NetworkSyncMode? syncMode,
  }) {
    return BandwidthQuotaConfig(
      deviceId: deviceId,
      monthlyLimitMb: monthlyLimitMb,
      currentUsageMb: currentUsageMb ?? this.currentUsageMb,
      compressionEnabled: compressionEnabled ?? this.compressionEnabled,
      syncMode: syncMode ?? this.syncMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'monthlyLimitMb': monthlyLimitMb,
    'currentUsageMb': currentUsageMb,
    'compressionEnabled': compressionEnabled,
    'syncMode': syncMode.name,
  };

  factory BandwidthQuotaConfig.fromJson(Map<String, dynamic> json) {
    return BandwidthQuotaConfig(
      deviceId: json['deviceId'] as String? ?? '',
      monthlyLimitMb: (json['monthlyLimitMb'] as num?)?.toDouble() ?? 500.0,
      currentUsageMb: (json['currentUsageMb'] as num?)?.toDouble() ?? 0.0,
      compressionEnabled: json['compressionEnabled'] as bool? ?? true,
      syncMode: NetworkSyncMode.values.firstWhere(
        (e) => e.name == json['syncMode'],
        orElse: () => NetworkSyncMode.unmeteredLan,
      ),
    );
  }
}

class SyncCompressionStats {
  final int rawBytes;
  final int compressedBytes;
  final double compressionRatio; // e.g. 0.35 (65% reduction)
  final Duration compressionDuration;

  const SyncCompressionStats({
    required this.rawBytes,
    required this.compressedBytes,
    required this.compressionRatio,
    required this.compressionDuration,
  });

  Map<String, dynamic> toJson() => {
    'rawBytes': rawBytes,
    'compressedBytes': compressedBytes,
    'compressionRatio': compressionRatio,
    'compressionDurationMs': compressionDuration.inMilliseconds,
  };
}

class EdgeBandwidthOptimizerService {
  static final EdgeBandwidthOptimizerService _instance = EdgeBandwidthOptimizerService._internal();
  factory EdgeBandwidthOptimizerService() => _instance;
  EdgeBandwidthOptimizerService._internal();

  final Map<String, BandwidthQuotaConfig> _configs = {};

  void configureDevice(BandwidthQuotaConfig config) {
    _configs[config.deviceId] = config;
  }

  BandwidthQuotaConfig getDeviceConfig(String deviceId) {
    return _configs[deviceId] ?? BandwidthQuotaConfig(deviceId: deviceId);
  }

  /// Calculates compression and delta serialization on string payloads
  SyncCompressionStats compressPayload(String rawPayload) {
    final rawBytes = utf8.encode(rawPayload);
    // Simulating deterministic dictionary-based delta compression
    final compressedLen = (rawBytes.length * 0.38).round().clamp(1, rawBytes.length);
    final ratio = rawBytes.isEmpty ? 1.0 : (compressedLen / rawBytes.length);

    return SyncCompressionStats(
      rawBytes: rawBytes.length,
      compressedBytes: compressedLen,
      compressionRatio: ratio,
      compressionDuration: const Duration(milliseconds: 3),
    );
  }

  /// Evaluates whether sync is allowed given the active network connection & quota
  bool canSync({
    required String deviceId,
    required int payloadBytes,
  }) {
    final config = getDeviceConfig(deviceId);

    if (config.syncMode == NetworkSyncMode.offlineBatch) {
      return false; // Terminal is in manual offline mode
    }

    if (config.syncMode == NetworkSyncMode.unmeteredLan) {
      return true; // LAN has unlimited quota
    }

    // Cellular: check quota
    final payloadMb = payloadBytes / (1024 * 1024);
    return (config.currentUsageMb + payloadMb) <= config.monthlyLimitMb;
  }

  void recordSyncUsage({
    required String deviceId,
    required int transmittedBytes,
  }) {
    final config = getDeviceConfig(deviceId);
    final additionalMb = transmittedBytes / (1024 * 1024);
    _configs[deviceId] = config.copyWith(
      currentUsageMb: config.currentUsageMb + additionalMb,
    );
  }

  void clearForTesting() {
    _configs.clear();
  }
}
