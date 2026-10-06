import '../domain/models/external_hardware_device.dart';

/// Real-time health monitoring and dynamic auto-failover engine for biometric devices.
class HardwareHealthFailoverService {
  final Map<String, ExternalHardwareDevice> _deviceRegistry = {};

  void registerDevice(ExternalHardwareDevice device) {
    _deviceRegistry[device.deviceId] = device;
  }

  void updateHeartbeat(String deviceId, {int? pendingLogs, DeviceHealthStatus? status}) {
    final dev = _deviceRegistry[deviceId];
    if (dev != null) {
      _deviceRegistry[deviceId] = dev.copyWith(
        lastHeartbeat: DateTime.now(),
        pendingLogsCount: pendingLogs ?? dev.pendingLogsCount,
        status: status ?? DeviceHealthStatus.online,
      );
    }
  }

  List<ExternalHardwareDevice> getOnlineDevices(String enterpriseId) {
    return _deviceRegistry.values
        .where((d) => d.enterpriseId == enterpriseId && d.isHealthy)
        .toList();
  }

  /// Locates the optimal secondary device in the same zone if primary fails.
  ExternalHardwareDevice? resolveFailoverDevice({
    required String failedDeviceId,
    required String enterpriseId,
  }) {
    final failed = _deviceRegistry[failedDeviceId];
    if (failed == null) return null;

    final candidates = _deviceRegistry.values.where((d) =>
        d.enterpriseId == enterpriseId &&
        d.deviceId != failedDeviceId &&
        d.isHealthy &&
        d.locationTag.toLowerCase() == failed.locationTag.toLowerCase());

    if (candidates.isNotEmpty) {
      // Pick the device with lowest pending logs
      final sorted = candidates.toList()
        ..sort((a, b) => a.pendingLogsCount.compareTo(b.pendingLogsCount));
      return sorted.first;
    }

    // Fallback: any healthy device in enterprise
    final anyHealthy = getOnlineDevices(enterpriseId);
    return anyHealthy.isNotEmpty ? anyHealthy.first : null;
  }

  /// Generates a fleet resilience score (0% to 100%).
  double calculateFleetResilience(String enterpriseId) {
    final enterpriseDevices = _deviceRegistry.values
        .where((d) => d.enterpriseId == enterpriseId)
        .toList();

    if (enterpriseDevices.isEmpty) return 100.0;
    final healthyCount = enterpriseDevices.where((d) => d.isHealthy).length;
    return (healthyCount / enterpriseDevices.length) * 100.0;
  }
}
