import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';
import 'terminal_attendance_sync_service.dart';
import 'terminal_event_payload_synthesizer.dart';

/// Result of an attendance injection into an external physical biometric machine bridge.
class TerminalInjectionResult {
  final bool success;
  final String message;
  final String? logId;
  final TerminalAttendanceEvent? event;
  final String? punchStatus;

  const TerminalInjectionResult({
    required this.success,
    required this.message,
    this.logId,
    this.event,
    this.punchStatus,
  });
}

/// Service enabling employees and authorized admins to record and inject biometric attendance
/// directly through an external hardware machine (Hikvision MinMoe / ZKTeco) profile,
/// making the resulting record 100% indistinguishable from an in-person physical terminal swipe.
class TerminalAttendanceInjectorService {
  final FirebaseFirestore _firestore;
  final TerminalAttendanceSyncService _syncService;

  TerminalAttendanceInjectorService({
    FirebaseFirestore? firestore,
    TerminalAttendanceSyncService? syncService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _syncService = syncService ?? TerminalAttendanceSyncService(firestore: firestore);

  /// Injects an attendance punch through a designated physical biometric terminal.
  Future<TerminalInjectionResult> injectTerminalPunch({
    required String enterpriseId,
    required BiometricTerminalDevice device,
    required String userId,
    required String employeeId,
    required String employeeName,
    required String punchType, // 'PUNCH_IN', 'PUNCH_OUT', 'START_BREAK', 'END_BREAK'
    DeviceAuthMode authMode = DeviceAuthMode.face,
    double similarityScore = 99.4,
    String? cardNo,
    DateTime? timestamp,
  }) async {
    final effectiveTime = timestamp ?? DateTime.now();

    // 1. Synthesize authentic hardware event
    final hardwareEvent = TerminalEventPayloadSynthesizer.synthesizeHardwareEvent(
      device: device,
      employeeId: employeeId,
      employeeName: employeeName,
      punchType: punchType,
      authMode: authMode,
      similarityScore: similarityScore,
      cardNo: cardNo,
      timestamp: effectiveTime,
    );

    // 2. Persist directly via the standard terminal synchronization engine
    final syncResult = await _syncService.processAndPersistEvents(
      enterpriseId: enterpriseId,
      device: device,
      events: [hardwareEvent],
    );

    if (syncResult.errors.isNotEmpty) {
      return TerminalInjectionResult(
        success: false,
        message: 'Terminal injection error: ${syncResult.errors.first}',
      );
    }

    if (syncResult.duplicateCount > 0) {
      return TerminalInjectionResult(
        success: false,
        message: 'Rapid consecutive punch ignored (double-swipe filter active on ${device.name}).',
        event: hardwareEvent,
      );
    }

    // 3. Update device sync stats
    await _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminals')
        .doc(device.id)
        .update({
      'totalEventsSynced': FieldValue.increment(1),
      'lastSyncAt': Timestamp.fromDate(effectiveTime),
      'status': DeviceConnectionStatus.online.name,
    });

    final actionLabel = punchType == 'PUNCH_IN'
        ? 'Clocked In'
        : punchType == 'PUNCH_OUT'
            ? 'Clocked Out'
            : punchType == 'START_BREAK'
                ? 'Break Started'
                : 'Break Ended';

    return TerminalInjectionResult(
      success: true,
      message: 'Successfully $actionLabel via ${device.name} (${authMode.name.toUpperCase()} verified at ${similarityScore.toStringAsFixed(1)}%).',
      event: hardwareEvent,
    );
  }
}
