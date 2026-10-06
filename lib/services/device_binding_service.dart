import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/registered_device.dart';

/// Service managing employee device bindings, tamper detection, and authorization
class DeviceBindingService {
  DeviceBindingService._internal();
  static final DeviceBindingService instance = DeviceBindingService._internal();

  /// Computes a deterministic cryptographic fingerprint for a device
  static String computeDeviceFingerprint({
    required String hardwareId,
    required String brand,
    required String model,
    required String enterpriseId,
  }) {
    final rawSeed = '$hardwareId:$brand:$model:$enterpriseId';
    return sha256.convert(utf8.encode(rawSeed)).toString();
  }

  /// Evaluates whether an incoming punch request originates from an authorized device
  bool validateDeviceForPunch({
    required RegisteredDevice device,
    required String currentFingerprint,
    bool enforceRootCheck = true,
  }) {
    if (!device.isAllowedToPunch) return false;
    if (device.deviceFingerprintSha256 != currentFingerprint) return false;
    if (enforceRootCheck && device.isJailbrokenOrRooted) return false;
    return true;
  }

  /// Enforces maximum allowed active devices per employee (default: 2)
  bool canEnrollNewDevice({
    required List<RegisteredDevice> existingDevices,
    int maxAllowed = 2,
  }) {
    final activeCount = existingDevices.where((d) =>
        d.status == DeviceTrustStatus.trusted ||
        d.status == DeviceTrustStatus.pendingVerification).length;
    return activeCount < maxAllowed;
  }

  /// Generates a quarantine record when an integrity violation occurs
  RegisteredDevice quarantineDevice({
    required RegisteredDevice device,
    required String reason,
  }) {
    debugPrint('[DeviceBindingService] Quarantining device ${device.deviceId}: $reason');
    return device.copyWith(
      status: DeviceTrustStatus.quarantined,
      lastActiveAt: DateTime.now(),
    );
  }
}
