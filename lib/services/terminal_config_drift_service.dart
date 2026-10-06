import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_config_baseline.dart';

/// Service for auditing physical hardware configurations against enterprise baselines
class TerminalConfigDriftService {
  /// Compares an active external device's configuration against a baseline
  static TerminalDriftReport auditDeviceConfig({
    required BiometricTerminalDevice device,
    required TerminalConfigBaseline baseline,
    DateTime? auditTime,
  }) {
    final discrepancies = <String>[];
    final now = auditTime ?? DateTime.now();

    final fw = device.customConfig['firmwareVersion'] as String? ?? '';
    if (fw.isNotEmpty && fw != baseline.firmwareVersionRequired) {
      discrepancies.add(
        'Firmware mismatch: running $fw, required ${baseline.firmwareVersionRequired}',
      );
    }

    final supportsFace = device.customConfig['supportsFace'] as bool? ?? true;
    if (baseline.requireFaceRecognition && !supportsFace) {
      discrepancies.add('Device capability violation: Face recognition is disabled or unsupported.');
    }

    return TerminalDriftReport(
      deviceId: device.id,
      hasDrift: discrepancies.isNotEmpty,
      driftDiscrepancies: discrepancies,
      evaluatedAt: now,
    );
  }
}
