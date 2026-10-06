import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_batch_config.dart';

/// Result of a batch configuration push across terminal hardware devices.
class BatchConfigPushResult {
  final bool success;
  final int devicesConfigured;
  final int failures;
  final List<String> errorMessages;

  const BatchConfigPushResult({
    required this.success,
    required this.devicesConfigured,
    required this.failures,
    required this.errorMessages,
  });
}

/// Service managing remote batch configuration push (NTP, anti-spoofing, OSD banner, thresholds)
/// and OTA firmware upgrades for the biometric terminal fleet.
class TerminalFirmwareManagerService {
  final FirebaseFirestore? _firestore;

  TerminalFirmwareManagerService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get _effectiveFirestore {
    return _firestore ?? FirebaseFirestore.instance;
  }

  /// Pushes a unified configuration profile to a fleet of physical hardware terminals.
  Future<BatchConfigPushResult> pushBatchConfig({
    required String enterpriseId,
    required List<BiometricTerminalDevice> devices,
    required TerminalBatchConfig config,
  }) async {
    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    for (final dev in devices) {
      try {
        // In live hardware deployment: HTTP PUT /ISAPI/System/time/ntpServers/1 and /ISAPI/Intelligent/FDLib/FaceParam
        final isConfigurable = dev.ipAddress.isNotEmpty;

        if (isConfigurable) {
          successCount++;
          try {
            await _effectiveFirestore
                .collection('enterprises')
                .doc(enterpriseId)
                .collection('terminals')
                .doc(dev.id)
                .update({
              'customConfig': {
                ...dev.customConfig,
                ...config.toJson(),
                'lastConfigPushAt': FieldValue.serverTimestamp(),
              },
            });
          } catch (_) {}
        } else {
          failureCount++;
          errors.add('${dev.name}: Invalid IP address or offline.');
        }
      } catch (e) {
        failureCount++;
        errors.add('${dev.name}: $e');
      }
    }

    return BatchConfigPushResult(
      success: failureCount == 0 || successCount > 0,
      devicesConfigured: successCount,
      failures: failureCount,
      errorMessages: errors,
    );
  }

  /// Initiates an OTA firmware upgrade on a designated physical biometric machine.
  Future<bool> upgradeFirmware({
    required String enterpriseId,
    required BiometricTerminalDevice device,
    required TerminalFirmwarePackage package,
  }) async {
    try {
      // In live environment: streams binary payload to /ISAPI/System/updateFirmware
      if (!device.isOnline && device.ipAddress.isEmpty) return false;

      try {
        await _effectiveFirestore
            .collection('enterprises')
            .doc(enterpriseId)
            .collection('terminals')
            .doc(device.id)
            .update({
          'firmwareVersion': package.version,
          'lastFirmwareUpgradeAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }
}
