import '../domain/models/zero_trust_access_evaluation.dart';

/// Service synthesizing multi-signal zero-trust contextual posture decisions
class ZeroTrustContextualPolicyService {
  ZeroTrustContextualPolicyService._internal();
  static final ZeroTrustContextualPolicyService instance = ZeroTrustContextualPolicyService._internal();

  /// Evaluates 5-tier zero-trust boundary before committing punch or unlocking access door
  ZeroTrustAccessEvaluation evaluateAccessRequest({
    required String userId,
    required String deviceId,
    required DeviceAccessTier tier,
    required bool isMtlsAuthenticated,
    required bool isHardwareKeystoreBacked,
    required bool isDevicePostureCompliant,
    required bool isLocationWithinGeofence,
    required bool isWithinScheduledShift,
    required double biometricConfidenceScore,
  }) {
    final now = DateTime.now();

    // 1. Biometric verification threshold check
    if (biometricConfidenceScore < 0.85) {
      return ZeroTrustAccessEvaluation(
        evaluationId: 'zta_${now.millisecondsSinceEpoch}',
        userId: userId,
        deviceId: deviceId,
        accessTier: tier,
        isMtlsAuthenticated: isMtlsAuthenticated,
        isHardwareKeystoreBacked: isHardwareKeystoreBacked,
        isDevicePostureCompliant: isDevicePostureCompliant,
        isLocationWithinGeofence: isLocationWithinGeofence,
        isWithinScheduledShift: isWithinScheduledShift,
        confidenceScore: biometricConfidenceScore,
        isAccessGranted: false,
        decisionReason: 'Insufficient biometric match confidence (${(biometricConfidenceScore * 100).toStringAsFixed(1)}%)',
        evaluatedAt: now,
      );
    }

    // 2. Hardware device posture check
    if (!isDevicePostureCompliant) {
      return ZeroTrustAccessEvaluation(
        evaluationId: 'zta_${now.millisecondsSinceEpoch}',
        userId: userId,
        deviceId: deviceId,
        accessTier: tier,
        isMtlsAuthenticated: isMtlsAuthenticated,
        isHardwareKeystoreBacked: isHardwareKeystoreBacked,
        isDevicePostureCompliant: false,
        isLocationWithinGeofence: isLocationWithinGeofence,
        isWithinScheduledShift: isWithinScheduledShift,
        confidenceScore: biometricConfidenceScore,
        isAccessGranted: false,
        decisionReason: 'Device posture failure (USB debugging, mock locations, or compromised OS)',
        evaluatedAt: now,
      );
    }

    // 3. Geofence presence check
    if (!isLocationWithinGeofence) {
      return ZeroTrustAccessEvaluation(
        evaluationId: 'zta_${now.millisecondsSinceEpoch}',
        userId: userId,
        deviceId: deviceId,
        accessTier: tier,
        isMtlsAuthenticated: isMtlsAuthenticated,
        isHardwareKeystoreBacked: isHardwareKeystoreBacked,
        isDevicePostureCompliant: isDevicePostureCompliant,
        isLocationWithinGeofence: false,
        isWithinScheduledShift: isWithinScheduledShift,
        confidenceScore: biometricConfidenceScore,
        isAccessGranted: false,
        decisionReason: 'GPS location is outside authorized enterprise branch geofence boundary',
        evaluatedAt: now,
      );
    }

    // 4. Restricted tier requires mTLS and Hardware Secure Enclave
    if (tier == DeviceAccessTier.restrictedAdminOnly || tier == DeviceAccessTier.securityStaff) {
      if (!isMtlsAuthenticated || !isHardwareKeystoreBacked) {
        return ZeroTrustAccessEvaluation(
          evaluationId: 'zta_${now.millisecondsSinceEpoch}',
          userId: userId,
          deviceId: deviceId,
          accessTier: tier,
          isMtlsAuthenticated: isMtlsAuthenticated,
          isHardwareKeystoreBacked: isHardwareKeystoreBacked,
          isDevicePostureCompliant: isDevicePostureCompliant,
          isLocationWithinGeofence: isLocationWithinGeofence,
          isWithinScheduledShift: isWithinScheduledShift,
          confidenceScore: biometricConfidenceScore,
          isAccessGranted: false,
          decisionReason: 'Privileged role requires hardware key-backed mTLS terminal credentials',
          evaluatedAt: now,
        );
      }
    }

    // All contextual signals satisfied
    return ZeroTrustAccessEvaluation(
      evaluationId: 'zta_${now.millisecondsSinceEpoch}',
      userId: userId,
      deviceId: deviceId,
      accessTier: tier,
      isMtlsAuthenticated: isMtlsAuthenticated,
      isHardwareKeystoreBacked: isHardwareKeystoreBacked,
      isDevicePostureCompliant: isDevicePostureCompliant,
      isLocationWithinGeofence: isLocationWithinGeofence,
      isWithinScheduledShift: isWithinScheduledShift,
      confidenceScore: biometricConfidenceScore,
      isAccessGranted: true,
      decisionReason: 'Zero-trust verified across biometric, hardware, posture, and geofence vectors',
      evaluatedAt: now,
    );
  }
}
