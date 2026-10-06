import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/external_biometric_device.dart';
import '../domain/models/terminal_sync_session_record.dart';
import 'hikvision_isapi_service.dart';
import 'terminal_attendance_sync_service.dart';

/// Background daemon and orchestrator for periodic external biometric terminal synchronization.
class TerminalSyncBackgroundWorker {
  final FirebaseFirestore _firestore;
  final HikvisionIsapiService _isapiService;
  final TerminalAttendanceSyncService _syncService;

  TerminalSyncBackgroundWorker({
    FirebaseFirestore? firestore,
    HikvisionIsapiService? isapiService,
    TerminalAttendanceSyncService? syncService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _isapiService = isapiService ?? HikvisionIsapiService(),
        _syncService = syncService ?? TerminalAttendanceSyncService(firestore: firestore);

  /// Synchronizes attendance logs from a single physical biometric device.
  Future<TerminalSyncSessionRecord> syncSingleDevice({
    required BiometricTerminalDevice device,
    TerminalSyncTrigger trigger = TerminalSyncTrigger.scheduledCron,
  }) async {
    final startTime = DateTime.now();
    final historyRef = _firestore
        .collection('enterprises')
        .doc(device.enterpriseId)
        .collection('terminals')
        .doc(device.id)
        .collection('sync_history')
        .doc();

    int eventsFetched = 0;
    int eventsSynced = 0;
    int duplicatesFiltered = 0;
    TerminalSyncStatus status = TerminalSyncStatus.success;
    String? errorMessage;

    try {
      List<TerminalAttendanceEvent> events = [];

      if (device.protocol == TerminalProtocol.hikvisionIsapi) {
        events = await _isapiService.fetchAttendanceEvents(
          device,
          startTime: device.lastSyncAt?.subtract(const Duration(minutes: 5)),
          maxResults: 150,
        );
      } else {
        // Generic / other protocol fallback
        events = [];
      }

      eventsFetched = events.length;

      if (events.isNotEmpty) {
        final syncResult = await _syncService.processAndPersistEvents(
          enterpriseId: device.enterpriseId,
          device: device,
          events: events,
        );
        eventsSynced = syncResult.normalizedCount;
        duplicatesFiltered = syncResult.duplicateCount;
      }

      // Update terminal status and total synced count
      await _firestore
          .collection('enterprises')
          .doc(device.enterpriseId)
          .collection('terminals')
          .doc(device.id)
          .update({
        'status': DeviceConnectionStatus.online.name,
        'lastSyncAt': Timestamp.fromDate(startTime),
        'totalEventsSynced': FieldValue.increment(eventsSynced),
        'lastErrorMessage': null,
      });
    } catch (e) {
      status = TerminalSyncStatus.failed;
      errorMessage = e.toString();

      await _firestore
          .collection('enterprises')
          .doc(device.enterpriseId)
          .collection('terminals')
          .doc(device.id)
          .update({
        'status': DeviceConnectionStatus.error.name,
        'lastErrorMessage': errorMessage,
      });
    }

    final record = TerminalSyncSessionRecord(
      id: historyRef.id,
      deviceId: device.id,
      enterpriseId: device.enterpriseId,
      startedAt: startTime,
      completedAt: DateTime.now(),
      status: status,
      trigger: trigger,
      eventsFetched: eventsFetched,
      eventsSynced: eventsSynced,
      duplicatesFiltered: duplicatesFiltered,
      errorMessage: errorMessage,
    );

    await historyRef.set(record.toMap());
    return record;
  }

  /// Synchronizes all auto-sync enabled terminals for an enterprise.
  Future<List<TerminalSyncSessionRecord>> syncAllEnterpriseDevices({
    required String enterpriseId,
    TerminalSyncTrigger trigger = TerminalSyncTrigger.scheduledCron,
  }) async {
    final query = await _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminals')
        .where('autoSyncEnabled', isEqualTo: true)
        .get();

    final List<TerminalSyncSessionRecord> results = [];
    for (final doc in query.docs) {
      final device = BiometricTerminalDevice.fromMap(doc.data(), id: doc.id);
      final record = await syncSingleDevice(device: device, trigger: trigger);
      results.add(record);
    }
    return results;
  }

  /// Streams recent sync history records for a terminal.
  Stream<List<TerminalSyncSessionRecord>> streamSyncHistory({
    required String enterpriseId,
    required String deviceId,
    int limit = 20,
  }) {
    return _firestore
        .collection('enterprises')
        .doc(enterpriseId)
        .collection('terminals')
        .doc(deviceId)
        .collection('sync_history')
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TerminalSyncSessionRecord.fromMap(doc.data(), id: doc.id))
            .toList());
  }
}
